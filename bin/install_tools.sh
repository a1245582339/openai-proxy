#!/bin/bash
# Tools Installation Script
# Automatically detect and install required tools: litellm[proxy] and openssl

set -e

echo "🔍 Checking required tools..."

# Check openssl
if ! command -v openssl &> /dev/null; then
    echo "⚠️  openssl not detected, installation required"
    if [ "$EUID" -eq 0 ]; then
        # Already root, install directly
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo apt-get install openssl"
                exit 1
            }
        elif command -v yum &> /dev/null; then
            yum install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo yum install openssl"
                exit 1
            }
        elif command -v dnf &> /dev/null; then
            dnf install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo dnf install openssl"
                exit 1
            }
        else
            echo "❌ Package manager not found, please install openssl manually"
            exit 1
        fi
        echo "✅ openssl installation complete"
    else
        # Need sudo privileges
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo apt-get install openssl"
                exit 1
            }
        elif command -v yum &> /dev/null; then
            sudo yum install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo yum install openssl"
                exit 1
            }
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y openssl || {
                echo "❌ Installation failed, please run manually: sudo dnf install openssl"
                exit 1
            }
        else
            echo "❌ Package manager not found, please install openssl manually"
            exit 1
        fi
        echo "✅ openssl installation complete"
    fi
else
    echo "✅ openssl already installed"
fi

# Check litellm
NEED_INSTALL_LITELLM=false

# Check if litellm is available
if ! command -v litellm &> /dev/null && ! python3 -c "import litellm" 2>/dev/null; then
    echo "⚠️  litellm not detected, installation required"
    NEED_INSTALL_LITELLM=true
fi

# Check backoff module (required for proxy functionality)
if ! python3 -c "import backoff" 2>/dev/null; then
    echo "⚠️  backoff module not detected (required for proxy), full version installation needed"
    NEED_INSTALL_LITELLM=true
fi

# Install litellm if needed
if [ "$NEED_INSTALL_LITELLM" = true ]; then
    echo "📦 Installing litellm[proxy]..."
    if [ "$EUID" -eq 0 ]; then
        # Already root, install directly
        pip3 install 'litellm[proxy]' || {
            echo "❌ Installation failed, please run manually: sudo pip3 install 'litellm[proxy]'"
            exit 1
        }
    else
        # Need sudo privileges
        sudo pip3 install 'litellm[proxy]' || {
            echo "❌ Installation failed, please run manually: sudo pip3 install 'litellm[proxy]'"
            exit 1
        }
    fi
    echo "✅ LiteLLM installation complete"
else
    echo "✅ LiteLLM dependencies ready"
fi

echo ""
