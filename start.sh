#!/bin/bash

# 时间记录器一键启动脚本
# Time Machine One-Click Startup Script

echo "🚀 启动时间记录器服务..."
echo "================================"

# 检查是否在正确的目录
if [ ! -f "README.md" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ 错误：请在项目根目录运行此脚本"
    exit 1
fi

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo "❌ 错误：未找到Go，请先安装Go语言环境"
    exit 1
fi

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ 错误：未找到Node.js，请先安装Node.js环境"
    exit 1
fi

# 检查npm是否安装
if ! command -v npm &> /dev/null; then
    echo "❌ 错误：未找到npm，请先安装npm包管理器"
    exit 1
fi

# 创建日志目录
mkdir -p backend/logs

echo "📦 检查前端依赖..."
cd frontend
if [ ! -d "node_modules" ]; then
    echo "📦 首次运行，正在安装前端依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ 前端依赖安装失败"
        exit 1
    fi
fi
cd ..

echo "🔧 检查后端依赖..."
cd backend
GOSUMDB=sum.golang.org go mod tidy
if [ $? -ne 0 ]; then
    echo "❌ 后端依赖检查失败"
    exit 1
fi
cd ..

# 定义清理函数
cleanup() {
    echo ""
    echo "🛑 正在停止服务..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
        echo "✅ 后端服务已停止"
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null
        echo "✅ 前端服务已停止"
    fi
    echo "👋 服务已全部停止，感谢使用！"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

echo "🔄 启动后端服务（端口：8080）..."
cd backend
GOSUMDB=sum.golang.org go run main.go &
BACKEND_PID=$!
cd ..

# 等待后端启动
sleep 3

# 检查后端是否启动成功
if ! curl -s http://localhost:8080/api/records > /dev/null; then
    echo "❌ 后端服务启动失败，请检查8080端口是否被占用"
    cleanup
fi

echo "✅ 后端服务启动成功！"
echo "🔄 启动前端服务（端口：3000）..."

cd frontend
npm start &
FRONTEND_PID=$!
cd ..

echo ""
echo "🎉 所有服务启动成功！"
echo "================================"
echo "📱 前端地址: http://localhost:3000"
echo "🔧 后端地址: http://localhost:8080"
echo "================================"
echo "💡 使用方法："
echo "   1. 在浏览器打开 http://localhost:3000"
echo "   2. 输入要记录的内容，按回车"
echo "   3. 输入花费时间（分钟），按回车保存"
echo "   4. 10秒内未输入时间将自动保存"
echo ""
echo "⚠️  按 Ctrl+C 停止所有服务"
echo ""

# 等待用户中断
wait
