# 🚀 LiteLLM OpenAI-to-Claude Proxy

将 OpenAI API 请求转发到 Claude 的代理服务。

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://hub.docker.com/r/your-org/litellm-openai-proxy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 📋 支持的启动方式

本项目支持 **两种启动方式**：

1. **🐳 Docker 容器启动**（✅ **推荐**）
   - 环境隔离，部署简单
   - 生产就绪，无需配置系统依赖
   - 支持快速构建和团队协作

2. **📜 Shell 脚本启动**
   - 传统方式，直接在主机运行
   - 适合开发调试
   - 需要手动管理依赖

> 💡 **推荐使用 Docker 容器启动方式**，更安全、更可靠，适合生产环境部署。

---

## 🎯 启动方式详解

### 方式一：Docker 容器启动（✅ 推荐）

**优势**：
- 🐳 容器化部署，环境隔离
- 🚀 快速构建，避免每次重新安装依赖
- 📦 生产就绪，支持健康检查
- 🔧 支持多端口 (443/8443)
- 👥 团队协作友好，可共享预构建基础镜像

**启动步骤**：

```bash
# 1. 首次构建（会自动构建基础镜像）
make build              # 或 ./build-image.sh

# 2. 启动服务
make run API_KEY=your-anthropic-api-key

# 3. 或直接使用 Docker
docker run -d \
  --name litellm-proxy \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY=your-key \
  litellm-openai-proxy

# 4. 测试服务
curl -k https://localhost:8443/v1/models
```

**两层构建架构**:
- 🏗️ **基础镜像** (`litellm-base`): 预装所有系统和Python依赖，构建一次，团队共享
- ⚡ **生产镜像** (`litellm-openai-proxy`): 仅复制配置文件，构建速度快 (<1分钟)

---

### 方式二：Shell 脚本启动

```bash
# 1. 启动代理服务（需要 root 权限）
sudo -E bin/start_litellm_proxy.sh

# 2. 测试服务
bin/test_proxy.sh

# 3. 停止服务
bin/stop_litellm_proxy.sh
```

**特点**:
- 📜 使用原始 shell 脚本
- 🔧 自动安装依赖 (openssl, litellm)
- 🔐 自动生成 SSL 证书
- 🌐 监听 443 端口，完美模拟 OpenAI API
- ⚠️ 需要 root 权限
- 🛠️ 适合开发和测试环境

---

## 💻 客户端集成

### Python (OpenAI SDK)

根据你选择的启动方式，使用对应的端口：

```python
import openai

# 🐳 Docker 容器启动方式（推荐）- 使用 8443 端口
client = openai.OpenAI(
    api_key="dummy-key",
    base_url="https://localhost:8443/v1"
)

# 📜 Shell 脚本启动方式 - 使用 443 端口
# client = openai.OpenAI(
#     api_key="dummy-key",
#     base_url="https://localhost/v1"  # 或 https://api.openai.com/v1
# )

# 使用 GPT-4 实际调用 Claude
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello Claude!"}]
)
print(response.choices[0].message.content)
```

## 🎯 模型映射

本项目将 OpenAI 模型请求映射到 Claude 模型，支持通过 `CLAUDE_MODEL` 环境变量配置目标模型。

| OpenAI 模型 | 映射到 Claude 模型 | 说明 |
|-------------|-------------------|------|
| `gpt-4` | `${CLAUDE_MODEL}` | 默认 `claude-sonnet-4-5` |
| `gpt-4o` | `${CLAUDE_MODEL}` | 默认 `claude-sonnet-4-5` |
| `gpt-4-turbo` | `${CLAUDE_MODEL}` | 默认 `claude-sonnet-4-5` |
| `gpt-5` | `${CLAUDE_MODEL}` | 默认 `claude-sonnet-4-5` |
| `gpt-3.5-turbo` | `${CLAUDE_MODEL}` | 默认 `claude-sonnet-4-5` |

**可用的 Claude 模型**：
- `claude-sonnet-4-5` - 平衡性能和成本（默认）
- `claude-opus-4` - 最高性能
- `claude-haiku-4` - 快速响应，低成本

**使用示例**：
```bash
# 使用 Opus 4 模型
export CLAUDE_MODEL="claude-opus-4"
sudo -E bin/start_litellm_proxy.sh

# Docker 方式
make run API_KEY=xxx MODEL=claude-opus-4
```

## 📁 项目结构

```
sentry-mcp-proxy/
├── 📜 脚本和配置
│   ├── bin/
│   │   ├── start_litellm_proxy.sh  # 启动服务
│   │   ├── stop_litellm_proxy.sh   # 停止服务
│   │   ├── test_proxy.sh           # 测试脚本
│   │   ├── install_tools.sh        # 依赖安装
│   │   └── setup_sentry_env.sh     # 环境配置
│   └── proxy-config.yaml           # 统一配置文件（支持两种启动方式）
│
├── 🐳 Docker 镜像部署
│   ├── Dockerfile.base              # 基础镜像 Dockerfile (预构建依赖)
│   ├── Dockerfile.production        # 生产 Dockerfile (快速构建)
│   ├── Makefile                     # 构建工具
│   ├── build-base.sh               # 基础镜像构建脚本
│   ├── build-image.sh              # 生产镜像构建脚本
│   ├── docker-compose.simple.yml   # Compose 配置
│   └── scripts/entrypoint.sh       # 容器启动脚本
│
└── 📚 文档
    ├── README.md                    # 主文档 (本文件)
    └── README-Production.md         # Docker 详细文档
```

## 🔧 管理命令

### Docker 容器方式（✅ 推荐）

```bash
# 使用 Makefile
make help          # 查看所有命令
make build         # 构建镜像（自动处理基础镜像）
make run API_KEY=xxx  # 启动容器
make logs          # 查看日志
make stop          # 停止容器
make clean         # 清理资源

# 手动构建基础镜像（可选）
./build-base.sh    # 构建基础镜像 litellm-base:latest
./build-image.sh   # 构建生产镜像 litellm-openai-proxy:latest

# 直接使用 Docker
docker ps                           # 查看容器
docker logs -f litellm-proxy       # 查看日志
docker stop litellm-proxy          # 停止容器
docker images | grep litellm       # 查看已构建的镜像
```

### Shell 脚本方式

```bash
# 启动 (需要 sudo)
sudo -E bin/start_litellm_proxy.sh

# 测试
bin/test_proxy.sh

# 停止
bin/stop_litellm_proxy.sh

# 查看进程
ps aux | grep litellm
```

---

## 🚀 快速开始

### 方式一：Docker 容器启动（✅ 推荐）

```bash
# 快速启动
git clone <repo> && cd sentry-mcp-proxy
make build
make run API_KEY=your-anthropic-api-key

# 测试
curl -k https://localhost:8443/v1/models
```

### 方式二：Shell 脚本启动

```bash
# 克隆并启动
git clone <repo> && cd sentry-mcp-proxy
sudo -E bin/start_litellm_proxy.sh

# 测试 (使用标准 OpenAI 地址)
curl -k https://api.openai.com/v1/models
```

## 📚 详细文档

- **Docker 部署详细指南**: [README-Production.md](README-Production.md)
- **配置文件说明**: 查看 `proxy-config.yaml`（统一配置文件，支持环境变量）
- **故障排除**: 检查各脚本的错误输出和日志

## ⚙️ 配置说明

项目使用统一的配置文件 `proxy-config.yaml`，支持通过环境变量动态配置：

**环境变量**：
- `ANTHROPIC_API_KEY`: Claude API Key（**必需**）
- `ANTHROPIC_BASE_URL`: Claude API 地址（可选，默认使用官方地址）
- `CLAUDE_MODEL`: Claude 模型名称（可选，默认 `claude-sonnet-4-5`）
  - 可选值：`claude-sonnet-4-5`, `claude-opus-4`, `claude-haiku-4` 等
- `DEBUG`: 调试模式开关（可选，`true`/`false`）

**配置示例**：

```bash
# Shell 脚本启动方式 - 设置环境变量
export ANTHROPIC_API_KEY="your-api-key"
export ANTHROPIC_BASE_URL="https://api.anthropic.com"
export CLAUDE_MODEL="claude-sonnet-4-5"
export DEBUG="false"

# 启动服务
sudo -E bin/start_litellm_proxy.sh
```

```bash
# Docker 容器启动方式 - 传递环境变量
docker run -d \
  --name litellm-proxy \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e CLAUDE_MODEL="claude-opus-4" \
  litellm-openai-proxy

# 或使用 Makefile
make run API_KEY=your-api-key MODEL=claude-opus-4
```

---

## 🎯 总结

本项目提供 **两种启动方式**：

| 启动方式 | 适用场景 | 端口 | 推荐度 |
|---------|---------|------|-------|
| 🐳 **Docker 容器** | 生产环境、团队协作 | 8443 | ✅ **推荐** |
| 📜 **Shell 脚本** | 开发测试、本地调试 | 443 | 可选 |

> 💡 **推荐使用 Docker 容器启动方式**，更安全、更可靠、更易于维护！

无论选择哪种方式，都能让任何 OpenAI 应用无缝使用 Claude！🎉