# LiteLLM Model Naming Guide

This guide explains how LiteLLM's model naming convention works and when to use different prefixes.

## 📚 Two Configuration Modes

### Mode 1: Direct Provider API (Recommended) ✅

**When to use**: Calling the provider's official API directly

**Characteristics**:
- Uses provider-specific prefix (e.g., `anthropic/`, `gemini/`, `azure/`)
- LiteLLM uses the provider's native API format
- No need to specify `api_base` (uses provider's default endpoint)
- Most reliable and feature-complete

**Example - Anthropic Claude**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: anthropic/claude-3-5-sonnet-20241022  # Provider prefix
      api_key: ${ANTHROPIC_API_KEY}
      # No api_base needed - uses https://api.anthropic.com by default
```

**Example - Google Gemini**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: gemini/gemini-1.5-pro  # Provider prefix
      api_key: ${GEMINI_API_KEY}
      # Uses https://generativelanguage.googleapis.com by default
```

**Example - Azure OpenAI**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: azure/gpt-4-deployment-name  # Provider prefix
      api_key: ${AZURE_API_KEY}
      api_base: ${AZURE_API_BASE}  # Your Azure endpoint
      api_version: "2024-02-15-preview"
```

### Mode 2: OpenAI-Compatible Custom Proxy

**When to use**: Your target endpoint provides an OpenAI-compatible interface

**Characteristics**:
- Uses `openai/` prefix with custom model name
- Must specify `api_base` pointing to your custom endpoint
- The endpoint should accept OpenAI request format
- Useful for self-hosted proxies or custom gateways

**Example - Custom OpenAI-Compatible Proxy**:
```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: openai/your-custom-model-name  # openai prefix
      api_key: ${API_KEY}
      api_base: https://your-custom-proxy.com/v1  # Custom endpoint
```

**Real-world scenario**:
You have a self-hosted service that:
1. Accepts requests in OpenAI format (`/v1/chat/completions`)
2. Internally routes to various LLM providers
3. Returns responses in OpenAI format

## 🎯 How to Choose?

### Use Provider Prefix (Mode 1) when:
- ✅ Calling official provider APIs (Anthropic, Google, AWS, Azure, etc.)
- ✅ You want maximum compatibility and features
- ✅ You want LiteLLM to handle provider-specific quirks
- ✅ Default configuration - recommended for most users

### Use `openai/` Prefix (Mode 2) when:
- ✅ Your backend is an OpenAI-compatible proxy/gateway
- ✅ You have a custom service that mimics OpenAI's API
- ✅ You're using a third-party service with OpenAI-compatible interface

## 📖 Provider Prefix Reference

| Provider | Prefix | Example Model |
|----------|--------|--------------|
| Anthropic | `anthropic/` | `anthropic/claude-3-5-sonnet-20241022` |
| Google Gemini | `gemini/` | `gemini/gemini-1.5-pro` |
| Azure OpenAI | `azure/` | `azure/your-deployment-name` |
| AWS Bedrock | `bedrock/` | `bedrock/anthropic.claude-3-5-sonnet` |
| Alibaba Qwen | `qwen/` | `qwen/qwen-max` |
| Zhipu AI | `zhipuai/` | `zhipuai/glm-4` |
| Mistral | `mistral/` | `mistral/mistral-large-latest` |
| DeepSeek | `deepseek/` | `deepseek/deepseek-chat` |
| Cohere | N/A (direct) | `command-r` |
| Hugging Face | `huggingface/` | `huggingface/meta-llama/Llama-2-7b` |
| Custom OpenAI | `openai/` | `openai/custom-model` + `api_base` |

## 🔍 Common Mistakes

### ❌ Wrong: Using openai/ with official Anthropic API
```yaml
model: openai/claude-3-5-sonnet-20241022
api_key: ${ANTHROPIC_API_KEY}
# Missing api_base or wrong - LiteLLM won't know where to send requests
```

### ✅ Correct: Using anthropic/ prefix
```yaml
model: anthropic/claude-3-5-sonnet-20241022
api_key: ${ANTHROPIC_API_KEY}
# LiteLLM knows to use https://api.anthropic.com
```

### ❌ Wrong: Provider prefix with custom proxy
```yaml
model: anthropic/custom-model
api_base: https://my-custom-proxy.com
# LiteLLM will try to use Anthropic's API format, may fail
```

### ✅ Correct: openai/ prefix with custom proxy
```yaml
model: openai/custom-model
api_base: https://my-custom-proxy.com
# LiteLLM uses OpenAI format, your proxy handles the rest
```

## 📝 Migration from Old Configuration

If your config previously used `openai/` prefix with `api_base` for Anthropic:

**Old (suboptimal)**:
```yaml
model: openai/claude-sonnet-4-5
api_key: ${ANTHROPIC_API_KEY}
api_base: ${ANTHROPIC_BASE_URL}
```

**New (recommended)**:
```yaml
model: anthropic/claude-3-5-sonnet-20241022
api_key: ${ANTHROPIC_API_KEY}
# No api_base needed
```

**Benefits**:
- Better error handling
- Native Anthropic features support
- Clearer configuration
- One less environment variable to manage

## 🔗 References

- [LiteLLM Providers Documentation](https://docs.litellm.ai/docs/providers)
- [LiteLLM Proxy Configuration](https://docs.litellm.ai/docs/proxy/configs)
- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference)
