#!/bin/bash
# LiteLLM 代理服务启动脚本
# 模拟 OpenAI API，将请求转发到 Claude

set -e

# 你自己的 API Key（替换成真实的）
export ANTHROPIC_API_KEY="sk-z7G8NEognLSx0f7DHafVKg"
# 你自己的 Base URL（比如你自己代理的Claude地址）
export ANTHROPIC_BASE_URL="https://litellm.kup-singapore-dev.metabit-trading.com/"

source ./setup_sentry_env.sh

# 代理监听端口 - 使用443端口模拟OpenAI API
PORT=443
HOST="0.0.0.0"

# SSL证书文件路径
SSL_CERT="./cert.pem"
SSL_KEY="./key.pem"

echo "🚀 启动 LiteLLM 代理服务 (模拟 OpenAI API)..."
echo "📡 监听地址: https://$HOST:$PORT"
echo "🔑 使用 ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:6}******"
echo "🌍 Base URL: $ANTHROPIC_BASE_URL"
echo "🔒 SSL证书: $SSL_CERT"
echo ""
echo "💡 现在所有访问 api.openai.com 的请求都会被转发到 Claude!"
echo "   测试命令: curl -k https://api.openai.com/v1/models"
echo ""

# 检查是否有权限绑定443端口
if [ "$PORT" -eq 443 ] && [ "$EUID" -ne 0 ]; then
    echo "⚠️  警告: 绑定443端口需要root权限"
    echo "   请使用: sudo -E ./start_litellm_proxy.sh"
    echo "   或者修改PORT为其他端口 (如8443)"
    exit 1
fi

# 检测并自动安装所需工具
./install_tools.sh

# 检查SSL证书是否存在
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "❌ SSL证书文件不存在，正在生成..."
    openssl req -x509 -newkey rsa:2048 -keyout "$SSL_KEY" -out "$SSL_CERT" -days 365 -nodes \
        -subj "/C=US/ST=CA/L=SF/O=LiteLLM/CN=api.openai.com"
    echo "✅ SSL证书生成完成"
fi

# 启动服务
# 使用 litellm 命令（root 用户和普通用户都已安装）
litellm \
  --config ./llm-proxy-config.yaml \
  --host $HOST \
  --port $PORT \
  --ssl_keyfile_path $SSL_KEY \
  --ssl_certfile_path $SSL_CERT \
  --num_workers 1 \
  --debug