#!/bin/bash

# Docker Web Environment 一键部署脚本
# 支持自动安装 Docker 并部署 Web 环境
# 支持 Ubuntu/Debian/CentOS/RHEL/Fedora 系统

set -e

echo "🚀 Docker Web Environment 一键部署"
echo "=================================="

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  检测到 root 用户，建议使用普通用户运行此脚本"
    echo "   如需继续，请按 Enter，否则按 Ctrl+C 退出"
    read
fi

# 检查 sudo 权限
if ! sudo -n true 2>/dev/null; then
    echo "🔐 需要 sudo 权限来安装 Docker，请输入密码："
    sudo -v
fi

# 检查 Docker 是否已安装
if command -v docker &> /dev/null; then
    echo "✅ Docker 已安装，版本: $(docker --version)"
else
    echo "❌ Docker 未安装，正在自动安装..."
    
    # 检测操作系统并安装 Docker
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo "❌ 无法检测操作系统"
        exit 1
    fi
    
    echo "📋 检测到操作系统: $OS $VER"
    
    case "$OS" in
        *"Ubuntu"*)
            echo "🔧 安装 Docker (Ubuntu)..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"Debian"*)
            echo "🔧 安装 Docker (Debian)..."
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            echo "🔧 安装 Docker (CentOS/RHEL)..."
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"Fedora"*)
            echo "🔧 安装 Docker (Fedora)..."
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            echo "请手动安装 Docker: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # 启动 Docker 服务
    echo "🚀 启动 Docker 服务..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到 docker 组
    echo "👤 添加用户到 docker 组..."
    sudo usermod -aG docker $USER
    
    echo "✅ Docker 安装完成！"
    echo "⚠️  请重新登录或运行 'newgrp docker' 后再次执行此脚本"
    exit 0
fi

# 检查 Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose 未正确安装"
    exit 1
fi

echo "✅ Docker Compose 已就绪"

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p /home/app/default
mkdir -p ./log

# 设置目录权限
echo "🔐 设置目录权限..."
chmod 755 /home/app/default
chmod 755 ./log

# 创建并设置应用日志目录权限
echo "📁 创建应用日志目录..."
mkdir -p /home/app/default/runtime/logs
mkdir -p /home/app/default/runtime/cache
mkdir -p /home/app/default/runtime/temp
chown -R www-data:www-data /home/app/default/runtime
chmod -R 755 /home/app/default/runtime
chmod -R 777 /home/app/default/runtime/logs
chmod -R 777 /home/app/default/runtime/cache
chmod -R 777 /home/app/default/runtime/temp

# 创建默认的测试文件（如果不存在）
echo "📝 检查并创建测试文件..."
if [ ! -f /home/app/default/index.php ]; then
    echo "✓ 创建 index.php"
    cat > /home/app/default/index.php << 'EOF'
<?php
echo "<h1>Hello from PHP!</h1>";
echo "<p>This is a custom Docker environment with PHP 8.3 and Nginx.</p>";
echo "<h2>PHP Information:</h2>";
phpinfo();
?>
EOF
else
    echo "⚠ index.php 已存在，跳过创建"
fi

if [ ! -f /home/app/default/health.php ]; then
    echo "✓ 创建 health.php"
    cat > /home/app/default/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION
]);
?>
EOF
else
    echo "⚠ health.php 已存在，跳过创建"
fi

# 构建并启动服务
echo "🔨 构建 Docker 镜像..."
docker compose build

echo "🚀 启动服务..."
docker compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 15

# 检查服务状态
echo "🔍 检查服务状态..."
if docker compose ps | grep -q "Up.*healthy\|Up.*unhealthy"; then
    echo "✅ 服务启动成功！"
    echo ""
    echo "🌐 访问地址:"
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "   - 主页: http://$SERVER_IP:80/"
    echo "   - 健康检查: http://$SERVER_IP:80/health.php"
    echo "   - PHP 信息: http://$SERVER_IP:80/index.php"
    echo ""
    echo "🛠️ 常用命令:"
    echo "   - 查看状态: docker compose ps"
    echo "   - 查看日志: docker compose logs"
    echo "   - 停止服务: docker compose down"
    echo "   - 重启服务: docker compose restart"
else
    echo "❌ 服务启动失败，请检查日志:"
    docker compose logs
    exit 1
fi

echo ""
echo "🎉 部署完成！"
echo "=================================="