# 🚀 LiteLLM OpenAI Proxy

A universal proxy service built on [LiteLLM](https://github.com/BerriAI/litellm) that forwards OpenAI API requests to 100+ LLM providers (Claude, Gemini, Qwen, GLM, etc.), enabling any application using the OpenAI SDK to seamlessly switch to alternative models without code changes.

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://hub.docker.com/r/your-org/litellm-openai-proxy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ✨ Key Features

- **Universal Compatibility**: Works with any application using OpenAI SDK (Python, Node.js, Java, etc.)
- **Zero Code Changes**: Simply point your OpenAI client to this proxy - no application modifications needed
- **Model Mapping**: Automatically maps GPT models (gpt-4, gpt-3.5-turbo, etc.) to Claude models
- **Flexible Deployment**: Supports both Docker container and shell script startup methods
- **Production Ready**: Includes SSL support, health checks, and proper error handling
- **Easy Integration**: Works with MCP servers, desktop applications, web services, CLI tools, and more

## 📖 About This Project

### What is This?

This project is a **production-ready wrapper around [LiteLLM Proxy](https://github.com/BerriAI/litellm)**, providing an easy-to-deploy solution for forwarding OpenAI API requests to 100+ alternative LLM providers (Claude, Gemini, Qwen, GLM, and more).

### Why This Project?

**Problem**: Many applications and tools are built using the OpenAI SDK/API, but you want to use alternative models (Claude, Gemini, local models, Chinese LLMs, etc.). Modifying application code is time-consuming, risky, and sometimes impossible (closed-source applications, third-party tools).

**Solution**: This proxy acts as a transparent middle layer that:
1. Accepts OpenAI-formatted API requests (same URL structure, same request format)
2. Automatically translates them to the target provider's format
3. Forwards to your chosen LLM provider (Claude, Gemini, Qwen, etc.)
4. Returns responses in OpenAI format

**Result**: Your applications think they're talking to OpenAI, but they're actually using your preferred LLM - no code changes required!

### How Does It Work?

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────────┐
│   Your App      │         │   This Proxy     │         │   LLM Providers     │
│                 │         │                  │         │                     │
│  OpenAI SDK     │ ------> │  LiteLLM Proxy   │ ------> │  • Anthropic/Claude │
│  (unchanged)    │  HTTP   │  + Config        │  HTTP   │  • Google/Gemini    │
│                 │ <------ │  (translation)   │ <------ │  • Alibaba/Qwen     │
│                 │         │                  │         │  • Zhipu/GLM        │
└─────────────────┘         └──────────────────┘         │  • AWS Bedrock      │
                                                          │  • Azure OpenAI     │
                                                          │  • 100+ more...     │
                                                          └─────────────────────┘
```

**Key Components**:
1. **LiteLLM Core**: Handles API translation and model routing for 100+ providers
2. **Configuration Layer**: Maps OpenAI models (gpt-4, gpt-3.5-turbo) to your chosen provider's models
3. **SSL/TLS Support**: Generates self-signed certificates for local development
4. **Docker Packaging**: Provides containerized deployment for production use

### What This Project Adds

While LiteLLM is powerful, it requires configuration and setup. This project provides:

✅ **Pre-configured Setup**: Ready-to-use configuration for OpenAI-to-LLM provider mapping (Claude by default, easily customizable)
✅ **Docker Images**: Two-tier build system (base + production) for fast deployments
✅ **Shell Scripts**: Simple startup/stop scripts for non-Docker environments
✅ **SSL Automation**: Automatic self-signed certificate generation
✅ **Production Optimizations**: Health checks disabled, parameter compatibility fixes (e.g., `reasoning_effort`)
✅ **Documentation**: Complete guides for both deployment methods + multi-provider examples
✅ **Environment Variables**: Easy configuration via env vars (API keys, models, debug mode)

### Technology Stack

- **[LiteLLM](https://github.com/BerriAI/litellm)**: Core proxy engine that handles API translation
- **Python 3.11+**: Runtime environment
- **Docker**: Containerization and deployment
- **OpenSSL**: SSL certificate generation
- **Bash**: Automation scripts

### 🌐 Multi-Provider Support

**This project is not limited to Anthropic/Claude!** Since it's built on LiteLLM, you can configure it to proxy to **100+ LLM providers** by simply modifying the configuration file.

**Supported Providers** (Examples):

| Provider | Models | Example Configuration |
|----------|--------|----------------------|
| **Anthropic** | Claude 3.5 Sonnet, Claude 3 Opus, etc. | `model: claude-3-5-sonnet-20241022` |
| **Google** | Gemini 1.5 Pro, Gemini 1.5 Flash | `model: gemini/gemini-1.5-pro` |
| **Azure OpenAI** | GPT-4, GPT-3.5 | `model: azure/your-deployment-name` |
| **AWS Bedrock** | Claude on Bedrock, Titan, etc. | `model: bedrock/anthropic.claude-3-5-sonnet` |
| **Alibaba Cloud** | Qwen (通义千问) | `model: qwen/qwen-max` |
| **Zhipu AI** | GLM-4 (智谱AI) | `model: zhipuai/glm-4` |
| **Mistral AI** | Mistral Large, etc. | `model: mistral/mistral-large-latest` |
| **DeepSeek** | DeepSeek Chat, Coder | `model: deepseek/deepseek-chat` |
| **Cohere** | Command R, Command R+ | `model: command-r` |
| **Hugging Face** | Open-source models | `model: huggingface/meta-llama/Llama-2-7b` |

**How to Configure**:

1. See `proxy-config.multi-provider.yaml.example` for a complete multi-provider configuration example
2. Modify `proxy-config.yaml` to add your desired providers
3. Set the corresponding API keys as environment variables
4. Restart the proxy

**Example: Switch to Google Gemini**:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: gemini/gemini-1.5-pro
      api_key: ${GEMINI_API_KEY}
```

Then start with:
```bash
GEMINI_API_KEY=your-key sudo -E bin/start_litellm_proxy.sh
```

Your OpenAI clients will now use Google Gemini instead!

**Mix Multiple Providers**:

You can even map different OpenAI models to different providers:
- `gpt-4` → Claude 3.5 Sonnet (Anthropic)
- `gpt-4-turbo` → Gemini 1.5 Pro (Google)
- `gpt-3.5-turbo` → Qwen Max (Alibaba)

This gives you ultimate flexibility in choosing the best model for each use case!

**Model Naming Rules**:

LiteLLM uses provider prefixes to determine which API to call:
- `anthropic/model-name` → Calls Anthropic API with native format
- `gemini/model-name` → Calls Google API
- `openai/model-name` + `api_base` → Calls custom OpenAI-compatible endpoint

📖 **Important**: See [Model Naming Guide](docs/MODEL_NAMING_GUIDE.md) for detailed explanation of when to use each prefix.

**More Providers**:

For the complete list of 100+ supported providers, see [LiteLLM's Provider Documentation](https://docs.litellm.ai/docs/providers).

## 🎯 Use Cases

This proxy can be used with any OpenAI-compatible application:
- **MCP Servers**: Any Model Context Protocol server or client that uses OpenAI
- **API Tools**: Postman, Insomnia, curl, or any HTTP client
- **SDKs**: OpenAI Python SDK, Node.js SDK, Java SDK, and others
- **Applications**: Chatbots, AI assistants, automation tools, data analysis scripts
- **Development**: Testing, debugging, cost optimization by switching between models

## 📋 Supported Startup Methods

This project supports **two startup methods**:

1. **🐳 Docker Container Startup** (✅ **Recommended**)
   - Environment isolation, simple deployment
   - Production-ready, no system dependency configuration needed
   - Supports fast builds and team collaboration

2. **📜 Shell Script Startup**
   - Traditional method, runs directly on host
   - Suitable for development and debugging
   - Requires manual dependency management

> 💡 **Docker container startup is recommended** - more secure, reliable, and suitable for production environments.

---

## 🎯 Startup Methods Explained

### Method 1: Docker Container Startup (✅ Recommended)

**Advantages**:
- 🐳 Containerized deployment, environment isolation
- 🚀 Fast builds, avoids reinstalling dependencies each time
- 📦 Production-ready, supports health checks
- 🔧 Supports multiple ports (443/8443)
- 👥 Team-friendly, can share pre-built base images

**Startup Steps**:

```bash
# 1. Initial build (automatically builds base image)
make build              # or ./build-image.sh

# 2. Start service (must provide API_KEY and BASE_URL)
make run API_KEY=your-anthropic-api-key BASE_URL=https://api.anthropic.com/

# 3. Or use Docker directly
docker run -d \
  --name litellm-proxy \
  --cap-add=NET_BIND_SERVICE \
  -p 443:443 \
  -e ANTHROPIC_API_KEY=your-key \
  -e ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
  litellm-openai-proxy

# 4. Test service
curl -k https://localhost:443/v1/models
```

**Two-tier Build Architecture**:
- 🏗️ **Base Image** (`litellm-base`): Pre-installed system and Python dependencies, build once, share with team
- ⚡ **Production Image** (`litellm-openai-proxy`): Only copies config files, builds fast (<1 minute)

---

### Method 2: Shell Script Startup

```bash
# 1. Start proxy service (requires root permission, must provide API_KEY and BASE_URL)
ANTHROPIC_API_KEY=your-key \
ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
sudo -E bin/start_litellm_proxy.sh

# 2. Test service
bin/test_proxy.sh

# 3. Stop service
bin/stop_litellm_proxy.sh
```

**Features**:
- 📜 Uses native shell scripts
- 🔧 Auto-installs dependencies (openssl, litellm)
- 🔐 Auto-generates SSL certificates
- 🌐 Listens on port 443, perfectly simulates OpenAI API
- ⚠️ Requires root permission
- 🛠️ Suitable for development and testing environments

---

## 💻 Client Integration

### Python (OpenAI SDK)

Use the corresponding port based on your chosen startup method:

```python
import openai

# Both startup methods use port 443
client = openai.OpenAI(
    api_key="dummy-key",
    base_url="https://localhost:443/v1"  # or https://localhost/v1
)

# Use GPT-4 to actually call Claude
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello Claude!"}]
)
print(response.choices[0].message.content)
```

## 🎯 Model Mapping

This project maps OpenAI model requests to Claude models, supports configuring target model via `CLAUDE_MODEL` environment variable.

| OpenAI Model | Maps to Claude Model | Description |
|-------------|-------------------|------|
| `gpt-4` | `${CLAUDE_MODEL}` | Defaults to `claude-sonnet-4-5` |
| `gpt-4o` | `${CLAUDE_MODEL}` | Defaults to `claude-sonnet-4-5` |
| `gpt-4-turbo` | `${CLAUDE_MODEL}` | Defaults to `claude-sonnet-4-5` |
| `gpt-5` | `${CLAUDE_MODEL}` | Defaults to `claude-sonnet-4-5` |
| `gpt-3.5-turbo` | `${CLAUDE_MODEL}` | Defaults to `claude-sonnet-4-5` |

**Available Claude Models**:
- `claude-sonnet-4-5` - Balanced performance and cost (default)
- `claude-opus-4` - Highest performance
- `claude-haiku-4` - Fast response, low cost

**Usage Examples**:
```bash
# Shell script method - Use Opus 4 model
ANTHROPIC_API_KEY=your-key \
ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
CLAUDE_MODEL=claude-opus-4 \
sudo -E bin/start_litellm_proxy.sh

# Docker method
make run API_KEY=your-key BASE_URL=https://api.anthropic.com/ MODEL=claude-opus-4
```

## 📁 Project Structure

```
openai-proxy/
├── 📜 Scripts and Configuration
│   ├── bin/
│   │   ├── start_litellm_proxy.sh  # Start service
│   │   ├── stop_litellm_proxy.sh   # Stop service
│   │   ├── test_proxy.sh           # Test script
│   │   ├── install_tools.sh        # Dependency installation
│   │   └── setup_client_env.sh     # Client environment configuration (optional)
│   └── proxy-config.yaml           # Unified config file (supports both startup methods)
│
├── 🐳 Docker Image Deployment
│   ├── Dockerfile.base              # Base image Dockerfile (pre-built dependencies)
│   ├── Dockerfile.production        # Production Dockerfile (fast build)
│   ├── Makefile                     # Build tools
│   ├── build-base.sh               # Base image build script
│   ├── build-image.sh              # Production image build script
│   ├── docker-compose.simple.yml   # Compose configuration
│   └── scripts/entrypoint.sh       # Container startup script
│
└── 📚 Documentation
    ├── README.md                    # Main documentation (this file)
    └── README-Production.md         # Docker detailed documentation
```

## 🔧 Management Commands

### Docker Container Method (✅ Recommended)

```bash
# Using Makefile
make help                                    # View all commands
make build                                   # Build image (automatically handles base image)
make run API_KEY=xxx BASE_URL=xxx           # Start container
make logs                                    # View logs
make stop                                    # Stop container
make clean                                   # Clean resources

# Manually build base image (optional)
./build-base.sh    # Build base image litellm-base:latest
./build-image.sh   # Build production image litellm-openai-proxy:latest

# Use Docker directly
docker ps                           # View containers
docker logs -f litellm-proxy       # View logs
docker stop litellm-proxy          # Stop container
docker images | grep litellm       # View built images
```

### Shell Script Method

```bash
# Start (requires sudo)
sudo -E bin/start_litellm_proxy.sh

# Test
bin/test_proxy.sh

# Stop
bin/stop_litellm_proxy.sh

# View process
ps aux | grep litellm
```

---

## 🚀 Quick Start

### Method 1: Docker Container Startup (✅ Recommended)

```bash
# Quick start
git clone <repo> && cd openai-proxy
make build
make run API_KEY=your-key BASE_URL=https://api.anthropic.com/

# Test
curl -k https://localhost:443/v1/models
```

### Method 2: Shell Script Startup

```bash
# Clone and start
git clone <repo> && cd openai-proxy
ANTHROPIC_API_KEY=your-key \
ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
sudo -E bin/start_litellm_proxy.sh

# Test
curl -k https://localhost:443/v1/models
```

## 🔧 Troubleshooting

### Error: 405 Method Not Allowed

**Symptom**:
```
httpx.HTTPStatusError: Client error '405 Method Not Allowed' for url 'https://your-custom-proxy.com'
```

**Root Cause**:

This error occurs when there's a mismatch between the model prefix in `proxy-config.yaml` and your `ANTHROPIC_BASE_URL` configuration.

**Two Configuration Scenarios**:

#### Scenario 1: Direct Anthropic API (Official)
If your `ANTHROPIC_BASE_URL` is `https://api.anthropic.com` (Anthropic's official API):

```yaml
# proxy-config.yaml
model: anthropic/claude-3-5-sonnet-20241022  # Use anthropic/ prefix
api_key: ${ANTHROPIC_API_KEY}
# No api_base needed, or api_base: https://api.anthropic.com
```

**How it works**: LiteLLM uses Anthropic's native API format to call the official endpoint.

#### Scenario 2: OpenAI-Compatible Custom Proxy (Your Internal Service)
If your `ANTHROPIC_BASE_URL` points to a custom proxy/gateway that accepts OpenAI-format requests:

```yaml
# proxy-config.yaml
model: openai/${CLAUDE_MODEL}                    # Use openai/ prefix
api_key: ${ANTHROPIC_API_KEY}
api_base: ${ANTHROPIC_BASE_URL}                  # Your custom proxy
```

**How it works**:
1. LiteLLM sends requests in **OpenAI format** to your custom proxy
2. Your proxy receives OpenAI-format requests
3. Your proxy internally forwards to the actual LLM provider

**Solution**:

Check your `ANTHROPIC_BASE_URL`:
- If it's `https://api.anthropic.com` → Use `anthropic/` prefix
- If it's a custom internal proxy (e.g., `https://your-company-proxy.com`) → Use `openai/` prefix

**Example Fix**:

For custom proxy (most common case):
```bash
# Rebuild with correct configuration
make build
make run API_KEY=your-key BASE_URL=https://your-custom-proxy.com
```

The `proxy-config.yaml` should use `openai/${CLAUDE_MODEL}` as the model prefix.

---

### Container Won't Start - Missing Environment Variables

**Symptom**:
```
❌ Error: Missing required environment variable ANTHROPIC_BASE_URL
```

**Solution**:

Both `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` are required:

```bash
# Docker method
make run API_KEY=your-key BASE_URL=https://api.anthropic.com/

# Or Docker directly
docker run -d \
  --name litellm-proxy \
  --cap-add=NET_BIND_SERVICE \
  -p 443:443 \
  -e ANTHROPIC_API_KEY=your-key \
  -e ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
  litellm-openai-proxy

# Shell script method
ANTHROPIC_API_KEY=your-key \
ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
sudo -E bin/start_litellm_proxy.sh
```

---

### Check Logs

**Docker container logs**:
```bash
docker logs -f litellm-proxy
```

**Shell script logs**:
Check terminal output or system logs where the script is running.

---

## 📚 Detailed Documentation

- **Docker Deployment Guide**: [README-Production.md](README-Production.md)
- **Configuration File**: See `proxy-config.yaml` (unified config file, supports environment variables)
- **Model Naming Guide**: [docs/MODEL_NAMING_GUIDE.md](docs/MODEL_NAMING_GUIDE.md)

## ⚙️ Configuration

Project uses unified config file `proxy-config.yaml`, supports dynamic configuration via environment variables:

**Environment Variables**:
- `ANTHROPIC_API_KEY`: Claude API Key (**required**)
- `ANTHROPIC_BASE_URL`: Claude API address (**required**)
- `CLAUDE_MODEL`: Claude model name (optional, defaults to `claude-sonnet-4-5`)
  - Available options: `claude-sonnet-4-5`, `claude-opus-4`, `claude-haiku-4`, etc.
- `DEBUG`: Debug mode switch (optional, `true`/`false`)

**Configuration Examples**:

```bash
# Shell script startup method - Set environment variables
ANTHROPIC_API_KEY="your-api-key" \
ANTHROPIC_BASE_URL="https://api.anthropic.com/" \
CLAUDE_MODEL="claude-sonnet-4-5" \
DEBUG="false" \
sudo -E bin/start_litellm_proxy.sh
```

```bash
# Docker container startup method - Pass environment variables
docker run -d \
  --name litellm-proxy \
  --cap-add=NET_BIND_SERVICE \
  -p 443:443 \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e ANTHROPIC_BASE_URL="https://api.anthropic.com/" \
  -e CLAUDE_MODEL="claude-opus-4" \
  litellm-openai-proxy

# Or use Makefile
make run API_KEY=your-api-key BASE_URL=https://api.anthropic.com/ MODEL=claude-opus-4
```

---

## 🎯 Summary

This project provides **two startup methods**:

| Startup Method | Use Case | Port | Recommendation |
|---------|---------|------|-------|
| 🐳 **Docker Container** | Production, team collaboration | 443 | ✅ **Recommended** |
| 📜 **Shell Script** | Development, local debugging | 443 | Optional |

> 💡 **Docker container startup is recommended** - more secure, reliable, and easier to maintain!

Either method allows any OpenAI application to seamlessly use Claude! 🎉