#!/bin/bash
# LiteLLM 代理测试脚本

echo "🧪 测试 LiteLLM 代理服务..."
echo ""

# 测试目标地址
PROXY_URL="https://localhost:443"
ALT_URL="https://api.openai.com"

echo "📡 测试地址: $PROXY_URL"
echo ""

# 1. 健康检查
echo "🏥 1. 健康检查..."
curl -k -s "$PROXY_URL/health" || echo "❌ 健康检查失败"
echo ""

# 2. 模型列表
echo "📋 2. 获取模型列表..."
curl -k -s "$PROXY_URL/v1/models" \
  -H "Authorization: Bearer dummy-key" | head -200 || echo "❌ 模型列表获取失败"
echo ""

# 3. 对话测试
echo "💬 3. 测试对话 API..."
curl -k -s "$PROXY_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "你好，请说一句话测试"}
    ],
    "max_tokens": 50
  }' | head -200 || echo "❌ 对话测试失败"
echo ""

# 4. 替代地址测试（如果配置了域名映射）
echo "🔄 4. 测试域名映射 (api.openai.com)..."
curl -k -s "$ALT_URL/v1/models" \
  -H "Authorization: Bearer dummy-key" | head -200 || echo "⚠️  域名映射未配置或不可用"
echo ""

echo "✅ 测试完成！"
echo ""
echo "💡 如果所有测试都成功，说明代理服务运行正常"
echo "   现在可以将 OpenAI 客户端指向 $PROXY_URL"