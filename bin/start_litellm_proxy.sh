#!/bin/bash
# LiteLLM 代理服务启动脚本
# 模拟 OpenAI API，将请求转发到 Claude

set -e

# 配置环境变量（可以在启动前修改）
# ANTHROPIC_API_KEY: Claude API Key（必需）
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-sk-J30wafT3BSPoO15HuXrGmA}"
# ANTHROPIC_BASE_URL: Claude API 地址（可选）
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://litellm.kup-singapore-dev.metabit-trading.com/}"
# CLAUDE_MODEL: Claude 模型名称（可选，默认 claude-sonnet-4-5）
export CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-5}"
# DEBUG: 调试模式（可选，true/false）
export DEBUG="${DEBUG:-false}"

source "$(dirname "$0")/setup_sentry_env.sh"

# 代理监听端口 - 使用443端口模拟OpenAI API
PORT=443
HOST="0.0.0.0"

# 获取项目根目录（bin目录的上一级）
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# SSL证书文件路径
SSL_CERT="$PROJECT_ROOT/cert.pem"
SSL_KEY="$PROJECT_ROOT/key.pem"

echo "🚀 启动 LiteLLM 代理服务 (模拟 OpenAI API)..."
echo "📡 监听地址: https://$HOST:$PORT"
echo "🔑 使用 ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:8}...$(echo ${ANTHROPIC_API_KEY} | tail -c 5)"
echo "🌍 Base URL: $ANTHROPIC_BASE_URL"
echo "🤖 Claude 模型: $CLAUDE_MODEL"
echo "🔒 SSL证书: $SSL_CERT"
echo "🐞 调试模式: $DEBUG"
echo ""
echo "💡 现在所有访问 api.openai.com 的请求都会被转发到 Claude!"
echo "   测试命令: curl -k https://api.openai.com/v1/models"
echo ""

# 检查是否有权限绑定443端口
if [ "$PORT" -eq 443 ] && [ "$EUID" -ne 0 ]; then
    echo "⚠️  警告: 绑定443端口需要root权限"
    echo "   请使用: sudo -E bin/start_litellm_proxy.sh"
    echo "   或者修改PORT为其他端口 (如8443)"
    exit 1
fi

# 检测并自动安装所需工具
"$(dirname "$0")/install_tools.sh"

# 检查SSL证书是否存在
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "❌ SSL证书文件不存在，正在生成..."
    openssl req -x509 -newkey rsa:2048 -keyout "$SSL_KEY" -out "$SSL_CERT" -days 365 -nodes \
        -subj "/C=US/ST=CA/L=SF/O=LiteLLM/CN=api.openai.com"
    echo "✅ SSL证书生成完成"
fi

# 生成临时配置文件（替换环境变量）
echo "🔧 生成配置文件（替换环境变量）..."
TEMP_CONFIG="/tmp/litellm-proxy-config-$$.yaml"

# 检查是否安装了 envsubst
if ! command -v envsubst &> /dev/null; then
    echo "⚠️  envsubst 未安装，尝试安装 gettext-base..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y gettext-base
    elif command -v yum &> /dev/null; then
        sudo yum install -y gettext
    fi
fi

# 使用 envsubst 替换环境变量
envsubst < "$PROJECT_ROOT/proxy-config.yaml" > "$TEMP_CONFIG"

if [ ! -f "$TEMP_CONFIG" ]; then
    echo "❌ 配置文件生成失败"
    exit 1
fi

echo "✅ 配置文件已生成: $TEMP_CONFIG"

# 清理函数
cleanup() {
    echo ""
    echo "🛑 正在停止服务..."
    rm -f "$TEMP_CONFIG"
    echo "👋 服务已停止"
    exit 0
}

trap cleanup SIGTERM SIGINT

# 启动服务
# 使用临时配置文件（已替换环境变量）
# 使用 litellm 命令（root 用户和普通用户都已安装）
litellm \
  --config "$TEMP_CONFIG" \
  --host $HOST \
  --port $PORT \
  --ssl_keyfile_path $SSL_KEY \
  --ssl_certfile_path $SSL_CERT \
  --num_workers 1 \
  $([ "$DEBUG" = "true" ] && echo "--debug" || echo "")