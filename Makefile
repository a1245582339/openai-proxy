# LiteLLM OpenAI-to-Claude Proxy - Makefile

.PHONY: help build build-base test run clean push

# Variable definitions
IMAGE_NAME := litellm-openai-proxy
BASE_IMAGE := litellm-base
VERSION := 1.0.3
PORT := 443

# Default target
help: ## Display help information
	@echo "🚀 LiteLLM OpenAI-to-Claude Proxy"
	@echo "================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build-base: ## Build base image (includes all dependencies)
	@echo "🏗️  Building base image $(BASE_IMAGE):latest..."
	./build-base.sh
	@echo "✅ Base image build complete!"

build: build-base ## Build production image (requires base image)
	@echo "🔨 Building production image $(IMAGE_NAME):$(VERSION)..."
	./build-image.sh
	@echo "✅ Production image build complete!"

build-fast: ## Fast build (assumes base image exists)
	@echo "⚡ Fast building image $(IMAGE_NAME):$(VERSION)..."
	docker build -f Dockerfile.production -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .
	@echo "✅ Fast build complete!"

test: build ## Build and test image
	@echo "🧪 Testing image..."
	@docker run --rm \
		--name $(IMAGE_NAME)-test \
		-p $(PORT):$(PORT) \
		-e ANTHROPIC_API_KEY=sk-test-key \
		-e ANTHROPIC_BASE_URL=https://api.anthropic.com/ \
		-e DEBUG=true \
		$(IMAGE_NAME):latest &
	@sleep 10
	@echo "✅ Test complete"
	@docker stop $(IMAGE_NAME)-test 2>/dev/null || true

run: ## Run container (requires API_KEY and BASE_URL, optional MODEL)
	@if [ -z "$(API_KEY)" ]; then \
		echo "❌ Error: Please set API_KEY environment variable"; \
		echo "   Usage: make run API_KEY=your-key BASE_URL=your-url"; \
		echo "   Optional: make run API_KEY=xxx BASE_URL=xxx MODEL=claude-opus-4"; \
		exit 1; \
	fi
	@if [ -z "$(BASE_URL)" ]; then \
		echo "❌ Error: Please set BASE_URL environment variable"; \
		echo "   Usage: make run API_KEY=your-key BASE_URL=your-url"; \
		echo "   Optional: make run API_KEY=xxx BASE_URL=xxx MODEL=claude-opus-4"; \
		exit 1; \
	fi
	@# Check and setup /etc/hosts
	@if ! grep -q "^127.0.0.1.*api\.openai\.com" /etc/hosts 2>/dev/null; then \
		./bin/setup_hosts.sh || true; \
	fi
	@echo "🚀 Starting container..."
	docker run -d \
		--name $(IMAGE_NAME) \
		--cap-add=NET_BIND_SERVICE \
		-p $(PORT):$(PORT) \
		-e PORT=$(PORT) \
		-e ANTHROPIC_API_KEY=$(API_KEY) \
		-e ANTHROPIC_BASE_URL=$(BASE_URL) \
		$(if $(MODEL),-e CLAUDE_MODEL=$(MODEL),) \
		$(IMAGE_NAME):latest
	@echo "✅ Container started"
	@echo "📡 Access URL: https://localhost:$(PORT)"
	@echo "🌍 Base URL: $(BASE_URL)"
	@if [ -n "$(MODEL)" ]; then echo "🤖 Using model: $(MODEL)"; fi

stop: ## Stop and remove container
	@echo "🛑 Stopping container..."
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	@echo "✅ Container stopped"

logs: ## View container logs
	@docker logs -f $(IMAGE_NAME)

clean: ## Clean images and containers
	@echo "🧹 Cleaning resources..."
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	@docker rmi $(IMAGE_NAME):latest $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@echo "✅ Cleanup complete"

clean-all: clean ## Clean all images (including base image)
	@echo "🧹 Cleaning all images..."
	@docker rmi $(BASE_IMAGE):latest 2>/dev/null || true
	@echo "✅ Complete cleanup finished"

push: build ## Push image to registry
	@echo "📤 Pushing image..."
	docker tag $(IMAGE_NAME):latest docker.io/$(IMAGE_NAME):latest
	docker tag $(IMAGE_NAME):$(VERSION) docker.io/$(IMAGE_NAME):$(VERSION)
	docker push docker.io/$(IMAGE_NAME):latest
	docker push docker.io/$(IMAGE_NAME):$(VERSION)
	@echo "✅ Push complete"

shell: ## Enter running container
	@docker exec -it $(IMAGE_NAME) /bin/bash

# Development commands
dev-build: ## Quick dev build (no cache)
	docker build --no-cache -f Dockerfile.production -t $(IMAGE_NAME):dev .

dev-run: dev-build ## Run in dev mode
	@if [ -z "$(API_KEY)" ]; then \
		echo "❌ Error: Please set API_KEY environment variable"; \
		exit 1; \
	fi
	@if [ -z "$(BASE_URL)" ]; then \
		echo "❌ Error: Please set BASE_URL environment variable"; \
		exit 1; \
	fi
	docker run --rm -it \
		-p $(PORT):$(PORT) \
		-e PORT=$(PORT) \
		-e ANTHROPIC_API_KEY=$(API_KEY) \
		-e ANTHROPIC_BASE_URL=$(BASE_URL) \
		$(if $(MODEL),-e CLAUDE_MODEL=$(MODEL),) \
		-e DEBUG=true \
		$(IMAGE_NAME):dev

# Shortcuts
all: clean build test ## Complete build and test workflow

status: ## Check container status
	@echo "📊 Container status:"
	@docker ps -a --filter name=$(IMAGE_NAME) --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

images: ## Display related images
	@echo "📦 Related images:"
	@echo "Base images:"
	@docker images $(BASE_IMAGE) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "  Base image not found"
	@echo ""
	@echo "Production images:"
	@docker images $(IMAGE_NAME) --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "  Production image not found"