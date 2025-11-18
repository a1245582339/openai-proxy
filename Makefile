# LiteLLM OpenAI-to-Claude Proxy - Makefile

.PHONY: help build test run clean push

# 变量定义
IMAGE_NAME := litellm-openai-proxy
VERSION := 1.0.0
PORT := 8443

# 默认目标
help: ## 显示帮助信息
	@echo "🚀 LiteLLM OpenAI-to-Claude Proxy"
	@echo "================================="
	@echo ""
	@echo "可用命令:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## 构建 Docker 镜像
	@echo "🔨 构建镜像 $(IMAGE_NAME):$(VERSION)..."
	docker build -f Dockerfile.production -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .
	@echo "✅ 构建完成!"

test: build ## 构建并测试镜像
	@echo "🧪 测试镜像..."
	@docker run --rm \
		--name $(IMAGE_NAME)-test \
		-p $(PORT):$(PORT) \
		-e ANTHROPIC_API_KEY=sk-test-key \
		-e DEBUG=true \
		$(IMAGE_NAME):latest &
	@sleep 10
	@echo "✅ 测试完成"
	@docker stop $(IMAGE_NAME)-test 2>/dev/null || true

run: ## 运行容器 (需要设置 API_KEY 环境变量)
	@if [ -z "$(API_KEY)" ]; then \
		echo "❌ 错误: 请设置 API_KEY 环境变量"; \
		echo "   使用方法: make run API_KEY=your-anthropic-api-key"; \
		exit 1; \
	fi
	@echo "🚀 启动容器..."
	docker run -d \
		--name $(IMAGE_NAME) \
		-p $(PORT):$(PORT) \
		-e ANTHROPIC_API_KEY=$(API_KEY) \
		$(IMAGE_NAME):latest
	@echo "✅ 容器已启动"
	@echo "📡 访问地址: https://localhost:$(PORT)"

stop: ## 停止并删除容器
	@echo "🛑 停止容器..."
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	@echo "✅ 容器已停止"

logs: ## 查看容器日志
	@docker logs -f $(IMAGE_NAME)

clean: ## 清理镜像和容器
	@echo "🧹 清理资源..."
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):latest $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@echo "✅ 清理完成"

push: build ## 推送镜像到仓库
	@echo "📤 推送镜像..."
	docker tag $(IMAGE_NAME):latest docker.io/$(IMAGE_NAME):latest
	docker tag $(IMAGE_NAME):$(VERSION) docker.io/$(IMAGE_NAME):$(VERSION)
	docker push docker.io/$(IMAGE_NAME):latest
	docker push docker.io/$(IMAGE_NAME):$(VERSION)
	@echo "✅ 推送完成"

shell: ## 进入运行中的容器
	@docker exec -it $(IMAGE_NAME) /bin/bash

# 开发相关命令
dev-build: ## 快速开发构建（无缓存）
	docker build --no-cache -f Dockerfile.production -t $(IMAGE_NAME):dev .

dev-run: dev-build ## 开发模式运行
	@if [ -z "$(API_KEY)" ]; then \
		echo "❌ 错误: 请设置 API_KEY 环境变量"; \
		exit 1; \
	fi
	docker run --rm -it \
		-p $(PORT):$(PORT) \
		-e ANTHROPIC_API_KEY=$(API_KEY) \
		-e DEBUG=true \
		$(IMAGE_NAME):dev

# 快捷命令
all: clean build test ## 完整的构建和测试流程

status: ## 检查容器状态
	@echo "📊 容器状态:"
	@docker ps -a --filter name=$(IMAGE_NAME) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

images: ## 显示相关镜像
	@echo "📦 相关镜像:"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"