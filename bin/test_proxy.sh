#!/bin/bash
# LiteLLM Proxy Test Script

echo "🧪 Testing LiteLLM Proxy Service..."
echo ""

# Test target URLs
PROXY_URL="https://localhost:443"
ALT_URL="https://api.openai.com"

echo "📡 Test URL: $PROXY_URL"
echo ""

# 1. Health check
echo "🏥 1. Health Check..."
curl -k -s "$PROXY_URL/health" || echo "❌ Health check failed"
echo ""

# 2. Model list
echo "📋 2. Get Model List..."
curl -k -s "$PROXY_URL/v1/models" \
  -H "Authorization: Bearer dummy-key" | head -200 || echo "❌ Failed to get model list"
echo ""

# 3. Chat test
echo "💬 3. Test Chat API..."
curl -k -s "$PROXY_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "Hello, please say one sentence for testing"}
    ],
    "max_tokens": 50
  }' | head -200 || echo "❌ Chat test failed"
echo ""

# 4. Alternative URL test (if domain mapping is configured)
echo "🔄 4. Test Domain Mapping (api.openai.com)..."
curl -k -s "$ALT_URL/v1/models" \
  -H "Authorization: Bearer dummy-key" | head -200 || echo "⚠️  Domain mapping not configured or unavailable"
echo ""

echo "✅ Testing Complete!"
echo ""
echo "💡 If all tests succeed, the proxy service is running correctly"
echo "   You can now point OpenAI clients to $PROXY_URL"
