#!/bin/bash
# Proxy Diagnostic Script
# Helps identify why the proxy is not receiving requests

set +e  # Don't exit on errors

echo "🔍 LiteLLM Proxy Diagnostics"
echo "============================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Proxy Running
echo "📊 Check 1: Is proxy running?"
echo "------------------------------"
DOCKER_RUNNING=$(docker ps 2>/dev/null | grep litellm-proxy)
PROCESS_RUNNING=$(ps aux 2>/dev/null | grep -E "[l]itellm.*proxy" | grep -v grep)

if [ -n "$DOCKER_RUNNING" ]; then
    echo -e "${GREEN}✓${NC} Docker container is running"
    docker ps | grep litellm-proxy
elif [ -n "$PROCESS_RUNNING" ]; then
    echo -e "${GREEN}✓${NC} Process is running"
    echo "$PROCESS_RUNNING"
else
    echo -e "${RED}✗${NC} Proxy is NOT running"
    echo "   Start it with: make run API_KEY=xxx BASE_URL=xxx"
    echo "   Or: sudo -E bin/start_litellm_proxy.sh"
    exit 1
fi
echo ""

# Check 2: Port Listening
echo "📡 Check 2: Is port 443 listening?"
echo "-----------------------------------"
PORT_LISTENING=$(sudo lsof -i :443 2>/dev/null | grep LISTEN)
if [ -n "$PORT_LISTENING" ]; then
    echo -e "${GREEN}✓${NC} Port 443 is listening"
    echo "$PORT_LISTENING"
else
    echo -e "${RED}✗${NC} Port 443 is NOT listening"
    echo "   Check if proxy started with errors"
    if [ -n "$DOCKER_RUNNING" ]; then
        echo "   View logs: docker logs litellm-proxy"
    fi
fi
echo ""

# Check 3: Direct Connection Test
echo "🔌 Check 3: Can we connect to proxy?"
echo "-------------------------------------"
MODELS_RESPONSE=$(curl -k -s https://localhost:443/v1/models 2>&1)
if echo "$MODELS_RESPONSE" | grep -q "object"; then
    echo -e "${GREEN}✓${NC} Proxy responds to /v1/models"
    echo "   Response: $(echo "$MODELS_RESPONSE" | head -c 100)..."
else
    echo -e "${RED}✗${NC} Proxy does NOT respond"
    echo "   Response: $MODELS_RESPONSE"
    echo "   This means proxy is not accessible at https://localhost:443"
fi
echo ""

# Check 4: Test Chat Completion
echo "💬 Check 4: Can we make a chat completion?"
echo "--------------------------------------------"
CHAT_RESPONSE=$(curl -k -s https://localhost:443/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Say hi"}],
    "max_tokens": 10
  }' 2>&1)

if echo "$CHAT_RESPONSE" | grep -q "content"; then
    echo -e "${GREEN}✓${NC} Chat completion works!"
    echo "   Response: $(echo "$CHAT_RESPONSE" | head -c 150)..."
    echo ""
    echo -e "${GREEN}==> Proxy is working correctly!${NC}"
    echo "    If MCP is not using it, check your client configuration."
else
    echo -e "${RED}✗${NC} Chat completion failed"
    echo "   Response: $CHAT_RESPONSE"
    echo "   Check ANTHROPIC_API_KEY and ANTHROPIC_BASE_URL are set correctly"
fi
echo ""

# Check 5: Hosts File (CRITICAL for MCP servers)
echo "🌐 Check 5: Hosts file configuration ⭐ CRITICAL"
echo "------------------------------------------------"
HOSTS_ENTRY=$(cat /etc/hosts 2>/dev/null | grep "api.openai.com" | grep -v "#")
if [ -n "$HOSTS_ENTRY" ]; then
    echo -e "${GREEN}✓${NC} Hosts file has api.openai.com entry:"
    echo "   $HOSTS_ENTRY"

    if echo "$HOSTS_ENTRY" | grep -q "127.0.0.1"; then
        echo -e "${GREEN}✓${NC} Points to localhost (correct!)"
    else
        echo -e "${RED}✗${NC} Does NOT point to localhost (should be 127.0.0.1)"
        echo "   Fix: sudo bin/setup_hosts.sh"
    fi
else
    echo -e "${RED}✗${NC} No api.openai.com entry in /etc/hosts"
    echo ""
    echo "   ⚠️  THIS IS THE #1 REASON PROXIES DON'T WORK!"
    echo "   Most MCP servers use api.openai.com as the endpoint."
    echo "   Without this entry, requests go to real OpenAI instead of your proxy."
    echo ""
    echo "   Quick fix:"
    echo "   sudo bin/setup_hosts.sh"
    echo ""
    echo "   Or manually:"
    echo "   echo '127.0.0.1  api.openai.com' | sudo tee -a /etc/hosts"
fi
echo ""

# Check 6: SSL Certificates
echo "🔒 Check 6: SSL Certificates"
echo "-----------------------------"
if [ -f "cert.pem" ] && [ -f "key.pem" ]; then
    echo -e "${GREEN}✓${NC} SSL certificates exist"
    CERT_INFO=$(openssl x509 -in cert.pem -noout -subject -dates 2>/dev/null)
    echo "   $CERT_INFO"

    # Check expiry
    EXPIRY=$(openssl x509 -in cert.pem -noout -enddate 2>/dev/null | cut -d= -f2)
    echo "   Expires: $EXPIRY"
else
    echo -e "${YELLOW}!${NC} SSL certificates not found in current directory"
    echo "   They should be auto-generated on first start"
fi
echo ""

# Check 7: MCP Configuration
echo "⚙️  Check 7: MCP Configuration"
echo "-------------------------------"
if [ "$(uname)" == "Darwin" ]; then
    MCP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    MCP_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
else
    MCP_CONFIG="$APPDATA/Claude/claude_desktop_config.json"
fi

if [ -f "$MCP_CONFIG" ]; then
    echo "   Found MCP config: $MCP_CONFIG"

    # Check for OPENAI_BASE_URL
    if grep -q "OPENAI_BASE_URL" "$MCP_CONFIG" 2>/dev/null; then
        BASE_URL=$(grep "OPENAI_BASE_URL" "$MCP_CONFIG" | head -1)
        echo "   $BASE_URL"

        if echo "$BASE_URL" | grep -q "localhost:443"; then
            echo -e "${GREEN}✓${NC} OPENAI_BASE_URL points to localhost:443"
        elif echo "$BASE_URL" | grep -q "localhost"; then
            echo -e "${YELLOW}!${NC} OPENAI_BASE_URL uses localhost but different port"
        else
            echo -e "${RED}✗${NC} OPENAI_BASE_URL does NOT point to localhost"
            echo "   MCP servers won't use your local proxy"
        fi

        # Check SSL verification
        if grep -q "NODE_TLS_REJECT_UNAUTHORIZED" "$MCP_CONFIG" 2>/dev/null; then
            TLS_CHECK=$(grep "NODE_TLS_REJECT_UNAUTHORIZED" "$MCP_CONFIG" | head -1)
            echo "   $TLS_CHECK"
            if echo "$TLS_CHECK" | grep -q '"0"'; then
                echo -e "${GREEN}✓${NC} SSL verification disabled (good for self-signed certs)"
            fi
        else
            echo -e "${YELLOW}!${NC} NODE_TLS_REJECT_UNAUTHORIZED not set"
            echo "   May cause SSL errors with self-signed certificates"
        fi
    else
        echo -e "${RED}✗${NC} No OPENAI_BASE_URL found in MCP config"
        echo "   MCP servers will use default OpenAI endpoint"
    fi
else
    echo "   MCP config not found at: $MCP_CONFIG"
    echo "   This is OK if you're not using MCP servers"
fi
echo ""

# Summary
echo "📋 Summary & Recommendations"
echo "============================="

# Check if basic connectivity works
if echo "$MODELS_RESPONSE" | grep -q "object"; then
    echo -e "${GREEN}✓ Proxy is running and accessible${NC}"
    echo ""

    # Check hosts file
    if [ -z "$HOSTS_ENTRY" ]; then
        echo -e "${RED}⚠️  CRITICAL: /etc/hosts is NOT configured!${NC}"
        echo ""
        echo "Most likely reason your MCP/clients aren't using the proxy:"
        echo "1. ⭐ Configure /etc/hosts (MOST IMPORTANT):"
        echo "   sudo bin/setup_hosts.sh"
        echo ""
        echo "After configuring hosts:"
        echo "2. Restart client application completely"
        echo "3. Monitor logs: docker logs -f litellm-proxy"
        echo "4. Test: curl -k https://api.openai.com:443/v1/models"
    else
        echo "If MCP/clients are still NOT using the proxy:"
        echo "1. Check client config has: OPENAI_BASE_URL=https://api.openai.com/v1"
        echo "   (or https://localhost:443/v1)"
        echo "2. Add: NODE_TLS_REJECT_UNAUTHORIZED=0 (for Node.js clients)"
        echo "3. Restart client application completely"
        echo "4. Monitor logs: docker logs -f litellm-proxy"
    fi
    echo ""
    echo "Detailed troubleshooting: docs/TROUBLESHOOTING.md"
else
    echo -e "${RED}✗ Proxy is NOT working properly${NC}"
    echo ""
    echo "To fix:"
    echo "1. Check proxy logs for errors"
    echo "2. Verify environment variables are set:"
    echo "   - ANTHROPIC_API_KEY"
    echo "   - ANTHROPIC_BASE_URL"
    echo "3. Try restarting the proxy"
    echo ""
    echo "View logs:"
    if [ -n "$DOCKER_RUNNING" ]; then
        echo "   docker logs litellm-proxy"
    else
        echo "   Check terminal where start_litellm_proxy.sh is running"
    fi
fi

echo ""
echo "For detailed troubleshooting guide, see: docs/TROUBLESHOOTING.md"
