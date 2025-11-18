#!/bin/bash
# Docker 镜像构建和发布脚本

set -e

# 镜像配置
IMAGE_NAME="litellm-openai-proxy"
IMAGE_TAG="latest"
REGISTRY="docker.io"  # 或者您的私有镜像仓库

# 版本信息
VERSION="1.0.0"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "🔨 构建 LiteLLM OpenAI-to-Claude 代理镜像"
echo "========================================"
echo "📦 镜像名称: ${IMAGE_NAME}"
echo "🏷️  镜像标签: ${IMAGE_TAG}"
echo "📅 构建时间: ${BUILD_DATE}"
echo "🔗 Git Hash: ${VCS_REF}"
echo ""

# 检查 Docker 环境
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker 未安装"
    exit 1
fi

echo "✅ Docker 环境检查完成"
echo ""

# 清理旧的构建缓存（可选）
read -p "🗑️  是否清理 Docker 构建缓存? [y/N]: " clean_cache
if [[ $clean_cache =~ ^[Yy]$ ]]; then
    echo "🧹 清理构建缓存..."
    docker builder prune -f
    echo "✅ 缓存清理完成"
fi

echo ""

# 构建镜像
echo "🔨 开始构建镜像..."
docker build \
    -f Dockerfile.production \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -t "${IMAGE_NAME}:${VERSION}" \
    -t "${IMAGE_NAME}:latest" \
    --build-arg BUILD_DATE="${BUILD_DATE}" \
    --build-arg VCS_REF="${VCS_REF}" \
    --build-arg VERSION="${VERSION}" \
    .

if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功!"
else
    echo "❌ 镜像构建失败"
    exit 1
fi

echo ""

# 显示镜像信息
echo "📋 镜像信息:"
docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""

# 测试镜像
echo "🧪 测试镜像..."
echo "   启动测试容器..."

# 使用测试 API Key 启动容器
TEST_API_KEY="sk-test-key-for-build-verification"
CONTAINER_ID=$(docker run -d \
    --name "${IMAGE_NAME}-test" \
    -p 18443:8443 \
    -e ANTHROPIC_API_KEY="${TEST_API_KEY}" \
    -e DEBUG=true \
    "${IMAGE_NAME}:${IMAGE_TAG}")

echo "   容器 ID: ${CONTAINER_ID:0:12}"

# 等待容器启动
echo "   等待服务启动..."
sleep 10

# 检查容器状态
if docker ps | grep -q "${IMAGE_NAME}-test"; then
    echo "✅ 测试容器启动成功"
else
    echo "❌ 测试容器启动失败"
    docker logs "${IMAGE_NAME}-test"
    docker rm -f "${IMAGE_NAME}-test" 2>/dev/null || true
    exit 1
fi

# 清理测试容器
echo "   清理测试容器..."
docker stop "${IMAGE_NAME}-test" >/dev/null 2>&1 || true
docker rm "${IMAGE_NAME}-test" >/dev/null 2>&1 || true

echo "✅ 镜像测试通过"
echo ""

# 询问是否推送到仓库
if [ "${REGISTRY}" != "local" ]; then
    read -p "📤 是否推送镜像到仓库 ${REGISTRY}? [y/N]: " push_image
    if [[ $push_image =~ ^[Yy]$ ]]; then
        echo "🚀 推送镜像到仓库..."

        # 标记镜像
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        docker tag "${IMAGE_NAME}:${VERSION}" "${REGISTRY}/${IMAGE_NAME}:${VERSION}"
        docker tag "${IMAGE_NAME}:latest" "${REGISTRY}/${IMAGE_NAME}:latest"

        # 推送镜像
        docker push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        docker push "${REGISTRY}/${IMAGE_NAME}:${VERSION}"
        docker push "${REGISTRY}/${IMAGE_NAME}:latest"

        echo "✅ 镜像推送完成"
        echo ""
        echo "📦 镜像地址:"
        echo "   ${REGISTRY}/${IMAGE_NAME}:latest"
        echo "   ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
    fi
fi

echo ""
echo "🎉 构建完成!"
echo ""
echo "📖 使用方法:"
echo "   # 基本使用"
echo "   docker run -d -p 8443:8443 -e ANTHROPIC_API_KEY=your-key ${IMAGE_NAME}"
echo ""
echo "   # 使用标准端口 (需要特权)"
echo "   docker run -d -p 443:443 -e ANTHROPIC_API_KEY=your-key -e PORT=443 ${IMAGE_NAME}"
echo ""
echo "   # 启用调试模式"
echo "   docker run -d -p 8443:8443 -e ANTHROPIC_API_KEY=your-key -e DEBUG=true ${IMAGE_NAME}"
echo ""
echo "   # 自定义 Claude API 地址"
echo "   docker run -d -p 8443:8443 \\"
echo "     -e ANTHROPIC_API_KEY=your-key \\"
echo "     -e ANTHROPIC_BASE_URL=https://your-claude-proxy.com \\"
echo "     ${IMAGE_NAME}"
echo ""
echo "🧪 测试命令:"
echo "   curl -k https://localhost:8443/v1/models"
echo ""