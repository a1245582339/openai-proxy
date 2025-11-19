#!/bin/bash
# Docker Proxy Service Test Script

set -e

PORT=443
HOST="localhost"

echo "🧪 Testing Docker LiteLLM Proxy Service"
echo "========================================"
echo ""

# Test /v1/models endpoint
echo "1️⃣ Testing Model List Endpoint..."
MODELS_RESPONSE=$(curl --noproxy "*" -k -s https://${HOST}:${PORT}/v1/models)

if echo "$MODELS_RESPONSE" | grep -q "gpt-4"; then
    echo "✅ Model list endpoint working"
    echo "   Available models: $(echo $MODELS_RESPONSE | grep -o '"id":"[^"]*"' | head -3)"
else
    echo "❌ Model list endpoint error"
    echo "   Response: $MODELS_RESPONSE"
    exit 1
fi

echo ""

# Test chat endpoint
echo "2️⃣ Testing Chat Endpoint..."
CHAT_RESPONSE=$(curl --noproxy "*" -k -s https://${HOST}:${PORT}/v1/chat/completions \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4","messages":[{"role":"user","content":"Say hello in 3 words"}]}')

if echo "$CHAT_RESPONSE" | grep -q "content"; then
    echo "✅ Chat endpoint working"
    CONTENT=$(echo "$CHAT_RESPONSE" | grep -o '"content":"[^"]*"' | head -1)
    echo "   Claude response: $CONTENT"
else
    echo "❌ Chat endpoint error"
    echo "   Response: $CHAT_RESPONSE"
    exit 1
fi

echo ""
echo "✅ All tests passed! Docker proxy service is running correctly"
echo ""
echo "📝 Note: If you encounter '403 from proxy' error, use the --noproxy parameter:"
echo "   curl --noproxy \"*\" -k https://localhost:443/v1/models"
