#!/bin/bash

# 时间记录器服务停止脚本
# Time Machine Service Stop Script

echo "🛑 正在停止时间记录器服务..."
echo "================================"

# 停止后端服务 (端口8080)
echo "🔍 查找后端服务进程..."
BACKEND_PIDS=$(lsof -ti:8080)
if [ ! -z "$BACKEND_PIDS" ]; then
    echo "📍 找到后端服务进程: $BACKEND_PIDS"
    for pid in $BACKEND_PIDS; do
        echo "🔪 停止进程 $pid..."
        kill -TERM $pid 2>/dev/null
        sleep 1
        # 如果进程仍然存在，强制杀死
        if kill -0 $pid 2>/dev/null; then
            echo "⚡ 强制停止进程 $pid..."
            kill -KILL $pid 2>/dev/null
        fi
    done
    echo "✅ 后端服务已停止"
else
    echo "ℹ️  未找到运行中的后端服务"
fi

# 停止前端服务 (端口3000)
echo "🔍 查找前端服务进程..."
FRONTEND_PIDS=$(lsof -ti:3000)
if [ ! -z "$FRONTEND_PIDS" ]; then
    echo "📍 找到前端服务进程: $FRONTEND_PIDS"
    for pid in $FRONTEND_PIDS; do
        echo "🔪 停止进程 $pid..."
        kill -TERM $pid 2>/dev/null
        sleep 1
        # 如果进程仍然存在，强制杀死
        if kill -0 $pid 2>/dev/null; then
            echo "⚡ 强制停止进程 $pid..."
            kill -KILL $pid 2>/dev/null
        fi
    done
    echo "✅ 前端服务已停止"
else
    echo "ℹ️  未找到运行中的前端服务"
fi

# 查找其他可能的Go进程（包含main.go）
echo "🔍 查找其他相关进程..."
OTHER_PIDS=$(ps aux | grep -E "(go run main.go|npm start)" | grep -v grep | awk '{print $2}')
if [ ! -z "$OTHER_PIDS" ]; then
    echo "📍 找到其他相关进程: $OTHER_PIDS"
    for pid in $OTHER_PIDS; do
        echo "🔪 停止进程 $pid..."
        kill -TERM $pid 2>/dev/null
        sleep 1
        if kill -0 $pid 2>/dev/null; then
            echo "⚡ 强制停止进程 $pid..."
            kill -KILL $pid 2>/dev/null
        fi
    done
    echo "✅ 其他相关进程已停止"
else
    echo "ℹ️  未找到其他相关进程"
fi

echo ""
echo "🎉 所有时间记录器服务已停止！"
echo "================================"
echo "💡 提示："
echo "   - 如需重新启动，请运行: ./start.sh"
echo "   - 如需查看服务状态，请运行: ./status.sh"
echo ""
