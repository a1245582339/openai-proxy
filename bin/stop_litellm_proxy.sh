#!/bin/bash
# LiteLLM Proxy Service Stop Script

echo "🛑 Stopping LiteLLM Proxy Service..."

# Find and kill litellm processes
if pgrep -f "litellm" > /dev/null; then
    echo "Found LiteLLM process, stopping..."
    pkill -f "litellm"
    sleep 2

    # Force kill if still running
    if pgrep -f "litellm" > /dev/null; then
        echo "Force stopping LiteLLM process..."
        pkill -9 -f "litellm"
    fi

    echo "✅ LiteLLM Proxy Service stopped"
else
    echo "⚠️  No running LiteLLM process found"
fi

echo "🔍 Current process status:"
ps aux | grep litellm | grep -v grep || echo "   No LiteLLM processes running"
