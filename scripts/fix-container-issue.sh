#!/bin/bash

# 修复Docker容器逃逸检测错误的脚本
# 解决 "current working directory is outside of container mount namespace root" 问题

set -e

echo "🔧 修复Docker容器工作目录问题..."

# 检查Docker版本
echo "📋 检查Docker版本..."
docker --version
docker compose version

# 停止现有容器
echo "🛑 停止现有容器..."
docker compose down || true

# 清理容器和镜像
echo "🧹 清理容器和镜像..."
docker system prune -f || true

# 确保目录存在且权限正确
echo "📁 创建并设置目录权限..."
sudo mkdir -p /home/app/default
sudo chown -R $USER:$USER /home/app/default
sudo chmod -R 755 /home/app/default

# 创建测试文件
echo "📄 创建测试文件..."
cat > /home/app/default/index.php << 'EOF'
<?php
phpinfo();
?>
EOF

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

# 重新构建镜像
echo "🔨 重新构建Docker镜像..."
docker compose build --no-cache

# 启动容器
echo "🚀 启动容器..."
docker compose up -d

# 等待容器启动
echo "⏳ 等待容器启动..."
sleep 10

# 检查容器状态
echo "📊 检查容器状态..."
docker compose ps

# 测试容器内部工作目录
echo "🔍 测试容器内部工作目录..."
docker compose exec web pwd
docker compose exec web ls -la /www/

# 健康检查
echo "🏥 执行健康检查..."
sleep 5
curl -f http://localhost/health.php || echo "健康检查失败，请检查日志"

echo "✅ 修复完成！"
echo "🌐 访问地址: http://localhost/"
echo "🏥 健康检查: http://localhost/health.php"
