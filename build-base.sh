#!/bin/bash
# 构建 LiteLLM 预构建基础镜像
# 这个脚本用于构建包含所有依赖的基础镜像，可以推送到镜像仓库供团队共享

set -e

IMAGE_NAME="litellm-base"
TAG="latest"
REGISTRY=""  # 可选：设置你的镜像仓库地址，如 registry.example.com/

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  构建 LiteLLM 基础镜像...${NC}"
echo -e "${YELLOW}镜像名称: ${IMAGE_NAME}:${TAG}${NC}"
echo ""

# 构建基础镜像
echo -e "${YELLOW}开始构建基础镜像...${NC}"
docker build -f Dockerfile.base -t "${IMAGE_NAME}:${TAG}" .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 基础镜像构建成功！${NC}"

    # 显示镜像信息
    echo -e "${BLUE}📊 镜像信息:${NC}"
    docker images "${IMAGE_NAME}:${TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

    echo ""
    echo -e "${GREEN}🎉 基础镜像构建完成！${NC}"
    echo -e "${YELLOW}下一步:${NC}"
    echo "  1. 使用基础镜像构建生产镜像:"
    echo "     ./build-image.sh"
    echo ""
    echo "  2. 或推送基础镜像到仓库 (可选):"
    if [ -n "$REGISTRY" ]; then
        echo "     docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}${IMAGE_NAME}:${TAG}"
        echo "     docker push ${REGISTRY}${IMAGE_NAME}:${TAG}"
    else
        echo "     docker tag ${IMAGE_NAME}:${TAG} your-registry/${IMAGE_NAME}:${TAG}"
        echo "     docker push your-registry/${IMAGE_NAME}:${TAG}"
    fi
    echo ""
    echo "  3. 团队成员可以直接拉取基础镜像:"
    if [ -n "$REGISTRY" ]; then
        echo "     docker pull ${REGISTRY}${IMAGE_NAME}:${TAG}"
    else
        echo "     docker pull your-registry/${IMAGE_NAME}:${TAG}"
    fi
else
    echo -e "${RED}❌ 基础镜像构建失败！${NC}"
    exit 1
fi