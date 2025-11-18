# 🚀 LiteLLM OpenAI-to-Claude Proxy

将 OpenAI API 请求转发到 Claude 的代理服务，支持**传统脚本**和**Docker 镜像**两种部署方式。

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://hub.docker.com/r/your-org/litellm-openai-proxy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 🎯 使用方法

### 方法一：传统脚本部署（原始方法）

```bash
# 1. 启动代理服务（需要 root 权限）
sudo -E ./start_litellm_proxy.sh

# 2. 测试服务
./test_proxy.sh

# 3. 停止服务
./stop_litellm_proxy.sh
```

**特点**:
- 📜 使用原始 shell 脚本
- 🔧 自动安装依赖 (openssl, litellm)
- 🔐 自动生成 SSL 证书
- 🌐 监听 443 端口，完美模拟 OpenAI API

### 方法二：Docker 镜像部署（推荐）

```bash
# 1. 使用 Makefile (推荐)
make build
make run API_KEY=your-anthropic-api-key

# 2. 或直接使用 Docker
docker run -d \
  --name litellm-proxy \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY=your-key \
  litellm-openai-proxy

# 3. 测试服务
curl -k https://localhost:8443/v1/models
```

**特点**:
- 🐳 容器化部署，环境隔离
- 🚀 一键启动，无需依赖管理
- 📦 生产就绪，支持健康检查
- 🔧 支持多端口 (443/8443)

## 💻 客户端集成

### Python (OpenAI SDK)

```python
import openai

# 方法一: 传统部署 (443端口)
client = openai.OpenAI(
    api_key="dummy-key",
    base_url="https://localhost/v1"  # 或 https://api.openai.com/v1
)

# 方法二: Docker 部署 (8443端口)
client = openai.OpenAI(
    api_key="dummy-key",
    base_url="https://localhost:8443/v1"
)

# 使用 GPT-4 实际调用 Claude
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello Claude!"}]
)
print(response.choices[0].message.content)
```

## 🎯 模型映射

| OpenAI 模型 | Claude 模型 | 用途 |
|-------------|-------------|------|
| `gpt-4` | `claude-sonnet-4` | 高性能对话 |
| `gpt-4o` | `claude-sonnet-4` | 多模态处理 |
| `gpt-3.5-turbo` | `claude-sonnet-4` | 快速响应 |

## 📁 项目结构

```
sentry-mcp-proxy/
├── 📜 传统脚本部署
│   ├── start_litellm_proxy.sh      # 启动服务
│   ├── stop_litellm_proxy.sh       # 停止服务
│   ├── test_proxy.sh               # 测试脚本
│   ├── install_tools.sh            # 依赖安装
│   ├── setup_sentry_env.sh         # 环境配置
│   └── llm-proxy-config.yaml       # LiteLLM 配置
│
├── 🐳 Docker 镜像部署
│   ├── Dockerfile.production        # 生产 Dockerfile
│   ├── Makefile                     # 构建工具
│   ├── build-image.sh              # 构建脚本
│   ├── docker-compose.simple.yml   # Compose 配置
│   ├── config/proxy-config.yaml    # 容器配置模板
│   └── scripts/entrypoint.sh       # 容器启动脚本
│
└── 📚 文档
    ├── README.md                    # 主文档 (本文件)
    └── README-Production.md         # Docker 详细文档
```

## 🔧 管理命令

### 传统脚本方式

```bash
# 启动 (需要 sudo)
sudo -E ./start_litellm_proxy.sh

# 测试
./test_proxy.sh

# 停止
./stop_litellm_proxy.sh

# 查看进程
ps aux | grep litellm
```

### Docker 方式

```bash
# 使用 Makefile
make help          # 查看所有命令
make build         # 构建镜像
make run API_KEY=xxx  # 启动容器
make logs          # 查看日志
make stop          # 停止容器
make clean         # 清理资源

# 直接使用 Docker
docker ps                           # 查看容器
docker logs -f litellm-proxy       # 查看日志
docker stop litellm-proxy          # 停止容器
```

## 🚀 快速开始

### 选择方式一：传统脚本（完全模拟 OpenAI）

```bash
# 克隆并启动
git clone <repo> && cd sentry-mcp-proxy
sudo -E ./start_litellm_proxy.sh

# 测试 (使用标准 OpenAI 地址)
curl -k https://api.openai.com/v1/models
```

### 选择方式二：Docker 镜像（推荐生产）

```bash
# 快速启动
git clone <repo> && cd sentry-mcp-proxy
make build
make run API_KEY=your-anthropic-api-key

# 测试
curl -k https://localhost:8443/v1/models
```

## 📚 详细文档

- **Docker 部署详细指南**: [README-Production.md](README-Production.md)
- **配置文件说明**: 查看 `llm-proxy-config.yaml` 和 `config/proxy-config.yaml`
- **故障排除**: 检查各脚本的错误输出和日志

---

**两种方式都能让任何 OpenAI 应用无缝使用 Claude！选择适合您的部署方式。** 🎉