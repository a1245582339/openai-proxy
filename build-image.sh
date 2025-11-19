#!/bin/bash
# Docker Image Build and Release Script

set -e

# Image configuration
IMAGE_NAME="litellm-openai-proxy"
IMAGE_TAG="latest"
REGISTRY="docker.io"  # or your private registry

# Version information
VERSION="1.0.3"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BASE_IMAGE="litellm-base:latest"

echo "🔨 Building LiteLLM OpenAI-to-Claude Proxy Image"
echo "================================================"
echo "📦 Image name: ${IMAGE_NAME}"
echo "🏷️  Image tag: ${IMAGE_TAG}"
echo "📅 Build time: ${BUILD_DATE}"
echo "🔗 Git Hash: ${VCS_REF}"
echo ""

# Check Docker environment
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not installed"
    exit 1
fi

echo "✅ Docker environment check complete"

# Check if base image exists
if ! docker image inspect "${BASE_IMAGE}" &>/dev/null; then
    echo ""
    echo "⚠️  Base image ${BASE_IMAGE} not found"
    echo ""
    read -p "🤔 Build base image automatically? [Y/n]: " build_base
    if [[ ! $build_base =~ ^[Nn]$ ]]; then
        echo "🏗️  Building base image..."
        ./build-base.sh
        if [ $? -ne 0 ]; then
            echo "❌ Base image build failed"
            exit 1
        fi
    else
        echo "❌ Base image required to continue"
        echo "   Please run: ./build-base.sh"
        exit 1
    fi
else
    echo "✅ Base image check passed: ${BASE_IMAGE}"
fi
echo ""

# Clean old build cache
echo "🧹 Cleaning build cache..."
docker builder prune -f
echo "✅ Cache cleanup complete"

echo ""

# Build image
echo "🔨 Building image..."
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
    echo "✅ Image built successfully!"
else
    echo "❌ Image build failed"
    exit 1
fi

echo ""

# Display image information
echo "📋 Image information:"
docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo ""

# Test image
echo "🧪 Testing image..."
echo "   Starting test container..."

# Start container with test API key
TEST_API_KEY="sk-test-key-for-build-verification"
TEST_BASE_URL="https://api.anthropic.com/"
CONTAINER_ID=$(docker run -d \
    --name "${IMAGE_NAME}-test" \
    -p 18443:8443 \
    -e ANTHROPIC_API_KEY="${TEST_API_KEY}" \
    -e ANTHROPIC_BASE_URL="${TEST_BASE_URL}" \
    -e DEBUG=true \
    "${IMAGE_NAME}:${IMAGE_TAG}")

echo "   Container ID: ${CONTAINER_ID:0:12}"

# Wait for container to start
echo "   Waiting for service to start..."
sleep 10

# Check container status
if docker ps | grep -q "${IMAGE_NAME}-test"; then
    echo "✅ Test container started successfully"
else
    echo "❌ Test container failed to start"
    docker logs "${IMAGE_NAME}-test"
    docker rm -f "${IMAGE_NAME}-test" 2>/dev/null || true
    exit 1
fi

# Clean up test container
echo "   Cleaning up test container..."
docker stop "${IMAGE_NAME}-test" >/dev/null 2>&1 || true
docker rm "${IMAGE_NAME}-test" >/dev/null 2>&1 || true

echo "✅ Image test passed"
echo ""
echo "🎉 Build complete!"
echo ""
echo "📖 Usage:"
echo "   # Using Makefile (recommended)"
echo "   make run API_KEY=your-key BASE_URL=https://api.anthropic.com/"
echo ""
echo "   # Or use Docker directly (requires API_KEY and BASE_URL)"
echo "   docker run -d --cap-add=NET_BIND_SERVICE -p 443:443 \\"
echo "     -e ANTHROPIC_API_KEY=your-key \\"
echo "     -e ANTHROPIC_BASE_URL=https://api.anthropic.com/ \\"
echo "     ${IMAGE_NAME}"
echo ""
echo "   # Enable debug mode"
echo "   docker run -d --cap-add=NET_BIND_SERVICE -p 443:443 \\"
echo "     -e ANTHROPIC_API_KEY=your-key \\"
echo "     -e ANTHROPIC_BASE_URL=https://api.anthropic.com/ \\"
echo "     -e DEBUG=true \\"
echo "     ${IMAGE_NAME}"
echo ""
echo "🧪 Test command:"
echo "   curl -k https://localhost:443/v1/models"
echo ""