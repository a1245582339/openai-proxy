#!/bin/bash
# LiteLLM Proxy 生产环境启动脚本

set -e

echo "🚀 LiteLLM OpenAI-to-Claude Proxy"
echo "================================="
echo "📦 Version: 1.0.0"
echo "🐍 Python: $(python3 --version)"
echo "⚡ LiteLLM: $(python3 -c 'import litellm; print(litellm.__version__)')"
echo ""

# 设置默认环境变量
export PORT=${PORT:-8443}
export HOST=${HOST:-0.0.0.0}
export DEBUG=${DEBUG:-false}
export ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-https://api.anthropic.com}
export SSL_CERT_PATH=${SSL_CERT_PATH:-/app/certs/cert.pem}
export SSL_KEY_PATH=${SSL_KEY_PATH:-/app/certs/key.pem}

echo "⚙️ 配置信息:"
echo "   监听地址: ${HOST}:${PORT}"
echo "   调试模式: ${DEBUG}"
echo "   Claude API: ${ANTHROPIC_BASE_URL}"

# 验证必需的环境变量
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "❌ 错误: 缺少必需的环境变量 ANTHROPIC_API_KEY"
    echo ""
    echo "使用方法:"
    echo "  docker run -d -p 8443:8443 -e ANTHROPIC_API_KEY=your-key litellm-openai-proxy"
    echo ""
    echo "获取 API Key: https://console.anthropic.com/"
    exit 1
fi

echo "   API Key: ${ANTHROPIC_API_KEY:0:8}...$(echo ${ANTHROPIC_API_KEY} | tail -c 5)"
echo ""

# 生成 SSL 证书
echo "🔐 准备 SSL 证书..."
if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
    echo "   生成自签名证书..."
    mkdir -p $(dirname "$SSL_CERT_PATH")

    openssl req -x509 -newkey rsa:2048 \
        -keyout "$SSL_KEY_PATH" \
        -out "$SSL_CERT_PATH" \
        -days 365 -nodes \
        -subj "/C=US/ST=CA/L=San Francisco/O=LiteLLM Proxy/CN=api.openai.com" \
        2>/dev/null

    echo "   ✅ SSL 证书生成完成"
else
    echo "   ✅ 使用现有证书"
fi

# 处理配置文件
echo "🔧 生成代理配置..."
CONFIG_TEMPLATE="/app/config/proxy-config.yaml"
CONFIG_OUTPUT="/app/config/litellm-config.yaml"

# 使用 envsubst 替换环境变量
envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

if [ ! -f "$CONFIG_OUTPUT" ]; then
    echo "❌ 配置文件生成失败"
    exit 1
fi

echo "   ✅ 配置文件已生成"

# 设置信号处理
cleanup() {
    echo ""
    echo "🛑 收到停止信号，正在优雅关闭..."
    if [ ! -z "$LITELLM_PID" ]; then
        kill -TERM "$LITELLM_PID" 2>/dev/null || true
        wait "$LITELLM_PID" 2>/dev/null || true
    fi
    echo "👋 服务已停止"
    exit 0
}

trap cleanup SIGTERM SIGINT

# 启动服务
echo "🚀 启动代理服务..."
echo ""
echo "📡 服务地址:"
echo "   HTTPS: https://localhost:${PORT}"
echo "   Health: https://localhost:${PORT}/health"
echo "   Models: https://localhost:${PORT}/v1/models"
echo ""

echo "🧪 测试命令:"
echo "   curl -k https://localhost:${PORT}/v1/models"
echo ""

echo "📊 OpenAI SDK 配置:"
echo "   import openai"
echo "   client = openai.OpenAI("
echo "       api_key='any-key',"
echo "       base_url='https://localhost:${PORT}/v1'"
echo "   )"
echo ""

# 启动 LiteLLM（后台运行以便处理信号）
litellm \
    --config "$CONFIG_OUTPUT" \
    --host "$HOST" \
    --port "$PORT" \
    --ssl_keyfile_path "$SSL_KEY_PATH" \
    --ssl_certfile_path "$SSL_CERT_PATH" \
    --num_workers 1 \
    $([ "$DEBUG" = "true" ] && echo "--debug" || echo "") &

LITELLM_PID=$!

echo "✅ 代理服务已启动 (PID: $LITELLM_PID)"
echo ""
echo "💡 现在所有 OpenAI API 请求将自动转发到 Claude!"
echo "   按 Ctrl+C 停止服务"
echo ""

# 等待进程
wait "$LITELLM_PID"