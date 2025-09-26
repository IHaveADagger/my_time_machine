#!/bin/bash

# 时间记录器服务状态检查脚本
# Time Machine Service Status Check Script

echo "📊 时间记录器服务状态检查"
echo "================================"

# 检查后端服务状态
echo "🔍 检查后端服务 (端口8080)..."
BACKEND_PIDS=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$BACKEND_PIDS" ]; then
    echo "✅ 后端服务运行中"
    echo "   进程ID: $BACKEND_PIDS"
    echo "   地址: http://localhost:8080"
    
    # 测试API是否响应
    if curl -s http://localhost:8080/api/records > /dev/null 2>&1; then
        echo "   API状态: 🟢 正常响应"
    else
        echo "   API状态: 🟡 服务启动中或异常"
    fi
else
    echo "❌ 后端服务未运行"
fi

echo ""

# 检查前端服务状态
echo "🔍 检查前端服务 (端口3000)..."
FRONTEND_PIDS=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$FRONTEND_PIDS" ]; then
    echo "✅ 前端服务运行中"
    echo "   进程ID: $FRONTEND_PIDS"
    echo "   地址: http://localhost:3000"
    
    # 测试前端是否响应
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "   状态: 🟢 正常响应"
    else
        echo "   状态: 🟡 服务启动中或异常"
    fi
else
    echo "❌ 前端服务未运行"
fi

echo ""

# 检查其他相关进程
echo "🔍 检查其他相关进程..."
GO_PROCESSES=$(ps aux | grep -E "go run main.go" | grep -v grep)
NPM_PROCESSES=$(ps aux | grep -E "npm start" | grep -v grep)

if [ ! -z "$GO_PROCESSES" ]; then
    echo "📍 Go进程:"
    echo "$GO_PROCESSES" | awk '{print "   PID: " $2 " | " $11 " " $12 " " $13}'
fi

if [ ! -z "$NPM_PROCESSES" ]; then
    echo "📍 npm进程:"
    echo "$NPM_PROCESSES" | awk '{print "   PID: " $2 " | " $11 " " $12}'
fi

if [ -z "$GO_PROCESSES" ] && [ -z "$NPM_PROCESSES" ]; then
    echo "ℹ️  未找到其他相关进程"
fi

echo ""
echo "================================"

# 综合状态判断
if [ ! -z "$BACKEND_PIDS" ] && [ ! -z "$FRONTEND_PIDS" ]; then
    echo "🎉 状态: 全部服务正常运行"
    echo "💡 访问: http://localhost:3000"
elif [ ! -z "$BACKEND_PIDS" ] || [ ! -z "$FRONTEND_PIDS" ]; then
    echo "⚠️  状态: 部分服务运行中"
    echo "💡 建议: 运行 ./stop.sh 然后 ./start.sh 重启所有服务"
else
    echo "🔴 状态: 所有服务已停止"
    echo "💡 启动: ./start.sh"
fi

echo ""
