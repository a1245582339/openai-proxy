#!/bin/bash
# LiteLLM Proxy Production Environment Startup Script

set -e

echo "🚀 LiteLLM OpenAI-to-Claude Proxy"
echo "================================="
echo "📦 Version: 1.0.0"
echo "🐍 Python: $(python3 --version)"
echo "⚡ LiteLLM: $(python3 -c 'import litellm; print(litellm.__version__)')"
echo ""

# Set default environment variables
export PORT=${PORT:-443}
export HOST=${HOST:-0.0.0.0}
export DEBUG=${DEBUG:-false}
export CLAUDE_MODEL=${CLAUDE_MODEL:-claude-sonnet-4-5}
export SSL_CERT_PATH=${SSL_CERT_PATH:-/app/certs/cert.pem}
export SSL_KEY_PATH=${SSL_KEY_PATH:-/app/certs/key.pem}

echo "⚙️ Configuration:"
echo "   Listen address: ${HOST}:${PORT}"
echo "   Debug mode: ${DEBUG}"
echo "   Claude model: ${CLAUDE_MODEL}"

# Validate required environment variables
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "❌ Error: Missing required environment variable ANTHROPIC_API_KEY"
    echo ""
    echo "Usage:"
    echo "  docker run -d -p 443:443 \\"
    echo "    -e ANTHROPIC_API_KEY=your-key \\"
    echo "    -e ANTHROPIC_BASE_URL=your-url \\"
    echo "    litellm-openai-proxy"
    echo ""
    echo "Or use Makefile:"
    echo "  make run API_KEY=your-key BASE_URL=your-url"
    exit 1
fi

if [ -z "$ANTHROPIC_BASE_URL" ]; then
    echo ""
    echo "❌ Error: Missing required environment variable ANTHROPIC_BASE_URL"
    echo ""
    echo "Usage:"
    echo "  docker run -d -p 443:443 \\"
    echo "    -e ANTHROPIC_API_KEY=your-key \\"
    echo "    -e ANTHROPIC_BASE_URL=your-url \\"
    echo "    litellm-openai-proxy"
    echo ""
    echo "Or use Makefile:"
    echo "  make run API_KEY=your-key BASE_URL=your-url"
    exit 1
fi

echo "   Claude API: ${ANTHROPIC_BASE_URL}"
echo "   API Key: ${ANTHROPIC_API_KEY:0:8}...$(echo ${ANTHROPIC_API_KEY} | tail -c 5)"
echo ""

# Generate SSL certificate
echo "🔐 Preparing SSL certificate..."
if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
    echo "   Generating self-signed certificate..."
    mkdir -p $(dirname "$SSL_CERT_PATH")

    openssl req -x509 -newkey rsa:2048 \
        -keyout "$SSL_KEY_PATH" \
        -out "$SSL_CERT_PATH" \
        -days 365 -nodes \
        -subj "/C=US/ST=CA/L=San Francisco/O=LiteLLM Proxy/CN=api.openai.com" \
        2>/dev/null

    echo "   ✅ SSL certificate generation complete"
else
    echo "   ✅ Using existing certificate"
fi

# Process configuration file
echo "🔧 Generating proxy configuration..."
CONFIG_TEMPLATE="/app/config/proxy-config.yaml"
CONFIG_OUTPUT="/tmp/litellm-config.yaml"

# Use envsubst to substitute environment variables to temporary directory (with write permission)
envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

if [ ! -f "$CONFIG_OUTPUT" ]; then
    echo "❌ Configuration file generation failed"
    exit 1
fi

echo "   ✅ Configuration file generated"

# Set signal handling
cleanup() {
    echo ""
    echo "🛑 Received stop signal, gracefully shutting down..."
    if [ ! -z "$LITELLM_PID" ]; then
        kill -TERM "$LITELLM_PID" 2>/dev/null || true
        wait "$LITELLM_PID" 2>/dev/null || true
    fi
    echo "👋 Service stopped"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start service
echo "🚀 Starting proxy service..."
echo ""
echo "📡 Service addresses:"
echo "   HTTPS: https://localhost:${PORT}"
echo "   Health: https://localhost:${PORT}/health"
echo "   Models: https://localhost:${PORT}/v1/models"
echo ""

echo "🧪 Test command:"
echo "   curl -k https://localhost:${PORT}/v1/models"
echo ""

echo "📊 OpenAI SDK configuration:"
echo "   import openai"
echo "   client = openai.OpenAI("
echo "       api_key='any-key',"
echo "       base_url='https://localhost:${PORT}/v1'"
echo "   )"
echo ""

# Start LiteLLM (run in background for signal handling)
litellm \
    --config "$CONFIG_OUTPUT" \
    --host "$HOST" \
    --port "$PORT" \
    --ssl_keyfile_path "$SSL_KEY_PATH" \
    --ssl_certfile_path "$SSL_CERT_PATH" \
    --num_workers 1 \
    $([ "$DEBUG" = "true" ] && echo "--debug" || echo "") &

LITELLM_PID=$!

echo "✅ Proxy service started (PID: $LITELLM_PID)"
echo ""
echo "💡 All OpenAI API requests will now be automatically forwarded to Claude!"
echo "   Press Ctrl+C to stop the service"
echo ""

# Wait for process
wait "$LITELLM_PID"
