# 🚀 LiteLLM OpenAI-to-Claude Proxy

**生产就绪的 Docker 镜像** - 让任何 OpenAI 应用无缝使用 Claude，无需修改代码！

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://hub.docker.com/r/your-org/litellm-openai-proxy)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-orange.svg)](#)

## ✨ 特性

- 🎯 **完全兼容** - 100% OpenAI API 兼容
- 🚀 **即开即用** - 单条 `docker run` 命令启动
- 🔐 **自动 HTTPS** - 内置 SSL 证书生成
- 🏥 **健康监控** - 内置健康检查端点
- 🛡️ **生产就绪** - 非 root 用户，安全配置
- 📊 **智能映射** - GPT-4 → Claude Sonnet，GPT-3.5 → Claude Haiku
- 🔧 **灵活配置** - 环境变量驱动配置

## 🚀 快速开始

### 基本使用

```bash
# 启动代理服务 (端口 8443)
docker run -d \
  --name litellm-proxy \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY=your-anthropic-api-key \
  litellm-openai-proxy

# 测试服务
curl -k https://localhost:8443/v1/models
```

### 标准端口 443

```bash
# 使用标准 HTTPS 端口 (需要特权)
sudo docker run -d \
  --name litellm-proxy \
  -p 443:443 \
  -e ANTHROPIC_API_KEY=your-anthropic-api-key \
  -e PORT=443 \
  litellm-openai-proxy
```

### 生产环境配置

```bash
# 生产环境推荐配置
docker run -d \
  --name litellm-proxy \
  --restart unless-stopped \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY=your-anthropic-api-key \
  -e ANTHROPIC_BASE_URL=https://api.anthropic.com \
  -e DEBUG=false \
  -v litellm_certs:/app/certs \
  -v litellm_logs:/app/logs \
  --memory=512m \
  --cpus=1.0 \
  litellm-openai-proxy
```

## 📋 环境变量

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| `ANTHROPIC_API_KEY` | ✅ | - | Anthropic API 密钥 |
| `ANTHROPIC_BASE_URL` | ❌ | `https://api.anthropic.com` | Claude API 基础地址 |
| `PORT` | ❌ | `8443` | 服务监听端口 |
| `HOST` | ❌ | `0.0.0.0` | 服务监听地址 |
| `DEBUG` | ❌ | `false` | 启用调试模式 |

## 🧪 测试验证

### 健康检查

```bash
# 检查服务状态
curl -k https://localhost:8443/health

# 期望响应
{"status": "healthy"}
```

### 模型列表

```bash
# 获取可用模型
curl -k https://localhost:8443/v1/models

# 期望响应
{
  "data": [
    {"id": "gpt-4", "object": "model"},
    {"id": "gpt-4o", "object": "model"},
    {"id": "gpt-3.5-turbo", "object": "model"}
  ]
}
```

### 对话测试

```bash
# 测试对话 API
curl -k https://localhost:8443/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer dummy-key" \
  -d '{
    "model": "gpt-4",
    "messages": [
      {"role": "user", "content": "Hello, Claude!"}
    ],
    "max_tokens": 100
  }'
```

## 💻 客户端集成

### Python (OpenAI SDK)

```python
import openai

# 配置客户端指向代理
client = openai.OpenAI(
    api_key="dummy-key",  # 代理不验证密钥
    base_url="https://localhost:8443/v1"
)

# 使用 GPT-4 实际调用 Claude
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "解释量子计算的基本原理"}
    ]
)

print(response.choices[0].message.content)
```

### Node.js

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: 'dummy-key',
  baseURL: 'https://localhost:8443/v1',
});

const response = await client.chat.completions.create({
  model: 'gpt-4',
  messages: [{ role: 'user', content: 'Hello from Node.js!' }],
});

console.log(response.choices[0].message.content);
```

### Go

```go
package main

import (
    "context"
    "fmt"
    "github.com/sashabaranov/go-openai"
)

func main() {
    config := openai.DefaultConfig("dummy-key")
    config.BaseURL = "https://localhost:8443/v1"
    client := openai.NewClientWithConfig(config)

    resp, err := client.CreateChatCompletion(
        context.Background(),
        openai.ChatCompletionRequest{
            Model: openai.GPT4,
            Messages: []openai.ChatCompletionMessage{
                {Role: "user", Content: "Hello from Go!"},
            },
        },
    )

    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    fmt.Println(resp.Choices[0].Message.Content)
}
```

## 🎯 模型映射

代理自动将 OpenAI 模型映射到对应的 Claude 模型：

| OpenAI 模型 | Claude 模型 | 特点 |
|-------------|-------------|------|
| `gpt-4` | `claude-3-5-sonnet-20241022` | 最强性能 |
| `gpt-4o` | `claude-3-5-sonnet-20241022` | 最强性能 |
| `gpt-4-turbo` | `claude-3-5-sonnet-20241022` | 最强性能 |
| `gpt-3.5-turbo` | `claude-3-haiku-20240307` | 快速响应 |
| `text-davinci-003` | `claude-3-sonnet-20240229` | 文本补全 |

## 🛠️ 管理命令

### Docker 基础命令

```bash
# 查看容器状态
docker ps -a --filter name=litellm-proxy

# 查看实时日志
docker logs -f litellm-proxy

# 重启服务
docker restart litellm-proxy

# 停止服务
docker stop litellm-proxy

# 删除容器
docker rm litellm-proxy
```

### 使用 Makefile

```bash
# 构建镜像
make build

# 运行服务 (需要 API Key)
make run API_KEY=your-anthropic-api-key

# 查看日志
make logs

# 停止服务
make stop

# 清理资源
make clean

# 查看所有命令
make help
```

## 🔧 高级配置

### 自定义配置文件

```bash
# 挂载自定义配置
docker run -d \
  -p 8443:8443 \
  -e ANTHROPIC_API_KEY=your-key \
  -v /path/to/your/config.yaml:/app/config/litellm-config.yaml:ro \
  litellm-openai-proxy
```

### 持久化证书

```bash
# 使用外部证书
docker run -d \
  -p 443:443 \
  -e ANTHROPIC_API_KEY=your-key \
  -e PORT=443 \
  -v /path/to/cert.pem:/app/certs/cert.pem:ro \
  -v /path/to/key.pem:/app/certs/key.pem:ro \
  litellm-openai-proxy
```

### Docker Compose

```yaml
version: '3.8'

services:
  litellm-proxy:
    image: litellm-openai-proxy:latest
    container_name: litellm-openai-proxy
    restart: unless-stopped
    ports:
      - "8443:8443"
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-https://api.anthropic.com}
      - DEBUG=false
    volumes:
      - litellm_certs:/app/certs
      - litellm_logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-k", "-f", "https://localhost:8443/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

volumes:
  litellm_certs:
  litellm_logs:
```

## 🏗️ 构建镜像

如果需要自己构建镜像：

```bash
# 克隆仓库
git clone https://github.com/your-org/litellm-openai-proxy.git
cd litellm-openai-proxy

# 构建镜像
./build-image.sh

# 或使用 Makefile
make build
```

## 🐛 故障排除

### 常见问题

**1. 容器启动失败**

```bash
# 检查日志
docker logs litellm-proxy

# 常见原因: API Key 未设置
docker run -e ANTHROPIC_API_KEY=your-key ...
```

**2. 无法访问服务**

```bash
# 检查端口映射
docker port litellm-proxy

# 检查防火墙设置
sudo ufw status
```

**3. SSL 证书问题**

```bash
# 忽略 SSL 验证 (仅测试用)
curl -k https://localhost:8443/health

# 或使用 HTTP 客户端时配置忽略证书验证
```

**4. 性能问题**

```bash
# 增加资源限制
docker update --memory=1g --cpus=2 litellm-proxy

# 或在启动时指定
docker run --memory=1g --cpus=2 ...
```

### 调试模式

```bash
# 启用调试日志
docker run -e DEBUG=true -e ANTHROPIC_API_KEY=your-key litellm-openai-proxy

# 查看详细启动过程
docker run --rm -it -e ANTHROPIC_API_KEY=your-key litellm-openai-proxy
```

### 健康检查

```bash
# 手动健康检查
curl -k https://localhost:8443/health

# 检查容器健康状态
docker inspect litellm-proxy | grep -A 10 Health
```

## 📊 监控指标

镜像内置基础监控端点：

- `GET /health` - 健康检查
- `GET /metrics` - 基础指标（如果启用）
- `GET /v1/models` - 可用模型列表

## 🔒 安全建议

### 生产环境

1. **使用有效 SSL 证书**
2. **设置防火墙规则**
3. **启用访问日志**
4. **定期更新镜像**
5. **使用密钥管理服务**

### 网络安全

```bash
# 仅允许本地访问
docker run -p 127.0.0.1:8443:8443 ...

# 使用自定义网络
docker network create litellm-network
docker run --network litellm-network ...
```

## 📚 API 文档

代理完全兼容 OpenAI API，支持以下端点：

- `GET /v1/models` - 获取模型列表
- `POST /v1/chat/completions` - 聊天对话
- `POST /v1/completions` - 文本补全
- `GET /health` - 健康检查

详细 API 文档请参考 [OpenAI API 官方文档](https://platform.openai.com/docs/api-reference)。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

---

**让您的 OpenAI 应用无缝使用 Claude 的强大能力！** 🚀