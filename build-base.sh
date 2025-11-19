#!/bin/bash
# Build LiteLLM Pre-built Base Image
# This script builds a base image with all dependencies, can be pushed to registry for team sharing

set -e

IMAGE_NAME="litellm-base"
TAG="latest"
REGISTRY=""  # Optional: set your registry address, e.g., registry.example.com/

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  Building LiteLLM base image...${NC}"
echo -e "${YELLOW}Image name: ${IMAGE_NAME}:${TAG}${NC}"
echo ""

# Build base image
echo -e "${YELLOW}Building base image...${NC}"
docker build -f Dockerfile.base -t "${IMAGE_NAME}:${TAG}" .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Base image built successfully!${NC}"

    # Display image information
    echo -e "${BLUE}📊 Image information:${NC}"
    docker images "${IMAGE_NAME}:${TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

    echo ""
    echo -e "${GREEN}🎉 Base image build complete!${NC}"
    echo -e "${YELLOW}Next step: Build production image using base image${NC}"
    echo "  ./build-image.sh"
else
    echo -e "${RED}❌ Base image build failed!${NC}"
    exit 1
fi