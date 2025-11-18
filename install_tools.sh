#!/bin/bash
# 工具安装脚本
# 自动检测并安装所需工具：litellm[proxy] 和 openssl

set -e

echo "🔍 检查所需工具..."

# 检查 openssl
if ! command -v openssl &> /dev/null; then
    echo "⚠️  未检测到 openssl，需要安装"
    if [ "$EUID" -eq 0 ]; then
        # 已经是 root，直接安装
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo apt-get install openssl"
                exit 1
            }
        elif command -v yum &> /dev/null; then
            yum install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo yum install openssl"
                exit 1
            }
        elif command -v dnf &> /dev/null; then
            dnf install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo dnf install openssl"
                exit 1
            }
        else
            echo "❌ 未找到包管理器，请手动安装 openssl"
            exit 1
        fi
        echo "✅ openssl 安装完成"
    else
        # 需要 sudo 权限安装
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo apt-get install openssl"
                exit 1
            }
        elif command -v yum &> /dev/null; then
            sudo yum install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo yum install openssl"
                exit 1
            }
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y openssl || {
                echo "❌ 安装失败，请手动运行: sudo dnf install openssl"
                exit 1
            }
        else
            echo "❌ 未找到包管理器，请手动安装 openssl"
            exit 1
        fi
        echo "✅ openssl 安装完成"
    fi
else
    echo "✅ openssl 已安装"
fi

# 检查 litellm
NEED_INSTALL_LITELLM=false

# 检测 litellm 是否可用
if ! command -v litellm &> /dev/null && ! python3 -c "import litellm" 2>/dev/null; then
    echo "⚠️  未检测到 litellm，需要安装"
    NEED_INSTALL_LITELLM=true
fi

# 检测 backoff 模块（proxy 功能必需）
if ! python3 -c "import backoff" 2>/dev/null; then
    echo "⚠️  未检测到 backoff 模块（proxy 功能依赖），需要安装完整版"
    NEED_INSTALL_LITELLM=true
fi

# 如果需要安装 litellm
if [ "$NEED_INSTALL_LITELLM" = true ]; then
    echo "📦 正在安装 litellm[proxy]..."
    if [ "$EUID" -eq 0 ]; then
        # 已经是 root，直接安装
        pip3 install 'litellm[proxy]' || {
            echo "❌ 安装失败，请手动运行: sudo pip3 install 'litellm[proxy]'"
            exit 1
        }
    else
        # 需要 sudo 权限安装
        sudo pip3 install 'litellm[proxy]' || {
            echo "❌ 安装失败，请手动运行: sudo pip3 install 'litellm[proxy]'"
            exit 1
        }
    fi
    echo "✅ LiteLLM 安装完成"
else
    echo "✅ LiteLLM 依赖已就绪"
fi

echo ""