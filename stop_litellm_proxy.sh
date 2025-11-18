#!/bin/bash
# LiteLLM 代理服务停止脚本

echo "🛑 停止 LiteLLM 代理服务..."

# 查找并杀死 litellm 进程
if pgrep -f "litellm" > /dev/null; then
    echo "找到 LiteLLM 进程，正在停止..."
    pkill -f "litellm"
    sleep 2

    # 强制杀死如果还在运行
    if pgrep -f "litellm" > /dev/null; then
        echo "强制停止 LiteLLM 进程..."
        pkill -9 -f "litellm"
    fi

    echo "✅ LiteLLM 代理服务已停止"
else
    echo "⚠️  未找到运行中的 LiteLLM 进程"
fi

echo "🔍 当前进程状态:"
ps aux | grep litellm | grep -v grep || echo "   无 LiteLLM 进程运行"