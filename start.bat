@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM 时间记录器一键启动脚本 (Windows)
REM Time Machine One-Click Startup Script for Windows

echo 🚀 启动时间记录器服务...
echo ================================

REM 检查是否在正确的目录
if not exist "README.md" (
    echo ❌ 错误：请在项目根目录运行此脚本
    pause
    exit /b 1
)
if not exist "backend" (
    echo ❌ 错误：未找到backend目录
    pause
    exit /b 1
)
if not exist "frontend" (
    echo ❌ 错误：未找到frontend目录
    pause
    exit /b 1
)

REM 检查Go是否安装
go version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到Go，请先安装Go语言环境
    pause
    exit /b 1
)

REM 检查Node.js是否安装
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到Node.js，请先安装Node.js环境
    pause
    exit /b 1
)

REM 检查npm是否安装
npm --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：未找到npm，请先安装npm包管理器
    pause
    exit /b 1
)

REM 创建日志目录
if not exist "backend\logs" mkdir backend\logs

echo 📦 检查前端依赖...
cd frontend
if not exist "node_modules" (
    echo 📦 首次运行，正在安装前端依赖...
    npm install
    if errorlevel 1 (
        echo ❌ 前端依赖安装失败
        pause
        exit /b 1
    )
)
cd ..

echo 🔧 检查后端依赖...
cd backend
go mod tidy
if errorlevel 1 (
    echo ❌ 后端依赖检查失败
    pause
    exit /b 1
)

echo 🔄 启动后端服务（端口：8080）...
start "时间记录器-后端" cmd /k "set GOSUMDB=sum.golang.org && go run main.go"

cd ..

REM 等待后端启动
echo ⏳ 等待后端服务启动...
timeout /t 5 /nobreak >nul

echo 🔄 启动前端服务（端口：3000）...
cd frontend
start "时间记录器-前端" cmd /k "npm start"
cd ..

echo.
echo 🎉 所有服务启动成功！
echo ================================
echo 📱 前端地址: http://localhost:3000
echo 🔧 后端地址: http://localhost:8080
echo ================================
echo 💡 使用方法：
echo    1. 在浏览器打开 http://localhost:3000
echo    2. 输入要记录的内容，按回车
echo    3. 输入花费时间（分钟），按回车保存
echo    4. 5秒内未输入时间将自动保存
echo.
echo ⚠️  关闭命令行窗口即可停止服务
echo.
pause
