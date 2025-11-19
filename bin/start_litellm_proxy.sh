#!/bin/bash
# LiteLLM Proxy Service Startup Script
# Simulates OpenAI API, forwards requests to Claude

set -e

# Environment Variables Configuration
# ANTHROPIC_API_KEY: Claude API Key (required)
# ANTHROPIC_BASE_URL: Claude API Address (required)
# CLAUDE_MODEL: Claude model name (optional, default: claude-sonnet-4-5)
# DEBUG: Debug mode (optional, true/false)

# Check required environment variables
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: Missing required environment variable ANTHROPIC_API_KEY"
    echo ""
    echo "Usage:"
    echo "  ANTHROPIC_API_KEY=your-key ANTHROPIC_BASE_URL=your-url sudo -E bin/start_litellm_proxy.sh"
    echo ""
    echo "Example:"
    echo "  ANTHROPIC_API_KEY=sk-ant-xxx \\"
    echo "  ANTHROPIC_BASE_URL=https://api.anthropic.com/ \\"
    echo "  sudo -E bin/start_litellm_proxy.sh"
    exit 1
fi

if [ -z "$ANTHROPIC_BASE_URL" ]; then
    echo "❌ Error: Missing required environment variable ANTHROPIC_BASE_URL"
    echo ""
    echo "Usage:"
    echo "  ANTHROPIC_API_KEY=your-key ANTHROPIC_BASE_URL=your-url sudo -E bin/start_litellm_proxy.sh"
    echo ""
    echo "Example:"
    echo "  ANTHROPIC_API_KEY=sk-ant-xxx \\"
    echo "  ANTHROPIC_BASE_URL=https://api.anthropic.com/ \\"
    echo "  sudo -E bin/start_litellm_proxy.sh"
    exit 1
fi

export ANTHROPIC_API_KEY
export ANTHROPIC_BASE_URL
export CLAUDE_MODEL="${CLAUDE_MODEL:-claude-sonnet-4-5}"
export DEBUG="${DEBUG:-false}"

# Optional: Set up client SSL environment variables (uncomment if needed for your client apps)
# source "$(dirname "$0")/setup_client_env.sh"

# Proxy listen port - Use port 443 to simulate OpenAI API
PORT=443
HOST="0.0.0.0"

# Get project root directory (parent directory of bin)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# SSL certificate file paths
SSL_CERT="$PROJECT_ROOT/cert.pem"
SSL_KEY="$PROJECT_ROOT/key.pem"

echo "🚀 Starting LiteLLM Proxy Service (simulating OpenAI API)..."
echo "📡 Listening on: https://$HOST:$PORT"
echo "🔑 Using ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:0:8}...$(echo ${ANTHROPIC_API_KEY} | tail -c 5)"
echo "🌍 Base URL: $ANTHROPIC_BASE_URL"
echo "🤖 Claude Model: $CLAUDE_MODEL"
echo "🔒 SSL Certificate: $SSL_CERT"
echo "🐞 Debug Mode: $DEBUG"
echo ""
echo "💡 All requests to api.openai.com will now be forwarded to Claude!"
echo "   Test command: curl -k https://api.openai.com/v1/models"
echo ""

# Check if we have permission to bind port 443
if [ "$PORT" -eq 443 ] && [ "$EUID" -ne 0 ]; then
    echo "⚠️  Warning: Binding port 443 requires root privileges"
    echo "   Please use: sudo -E bin/start_litellm_proxy.sh"
    echo "   Or change PORT to another port (e.g., 8443)"
    exit 1
fi

# Detect and auto-install required tools
"$(dirname "$0")/install_tools.sh"

# Check if SSL certificates exist
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "❌ SSL certificate files not found, generating..."
    openssl req -x509 -newkey rsa:2048 -keyout "$SSL_KEY" -out "$SSL_CERT" -days 365 -nodes \
        -subj "/C=US/ST=CA/L=SF/O=LiteLLM/CN=api.openai.com"
    echo "✅ SSL certificate generation complete"
fi

# Generate temporary config file (substitute environment variables)
echo "🔧 Generating config file (substituting environment variables)..."
TEMP_CONFIG="/tmp/litellm-proxy-config-$$.yaml"

# Check if envsubst is installed
if ! command -v envsubst &> /dev/null; then
    echo "⚠️  envsubst not installed, attempting to install gettext-base..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y gettext-base
    elif command -v yum &> /dev/null; then
        sudo yum install -y gettext
    fi
fi

# Use envsubst to substitute environment variables
envsubst < "$PROJECT_ROOT/proxy-config.yaml" > "$TEMP_CONFIG"

if [ ! -f "$TEMP_CONFIG" ]; then
    echo "❌ Config file generation failed"
    exit 1
fi

echo "✅ Config file generated: $TEMP_CONFIG"

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Stopping service..."
    rm -f "$TEMP_CONFIG"
    echo "👋 Service stopped"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start service
# Use temporary config file (with substituted environment variables)
# Use litellm command (installed for both root and regular users)
litellm \
  --config "$TEMP_CONFIG" \
  --host $HOST \
  --port $PORT \
  --ssl_keyfile_path $SSL_KEY \
  --ssl_certfile_path $SSL_CERT \
  --num_workers 1 \
  $([ "$DEBUG" = "true" ] && echo "--debug" || echo "")
