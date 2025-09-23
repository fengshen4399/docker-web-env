#!/bin/bash

# 打包脚本 - 创建部署包

set -e

VERSION=${1:-"1.4.0"}
PACKAGE_NAME="docker-web-env-v${VERSION}"
RELEASES_DIR="/home/releases"

# 确保 releases 目录存在
mkdir -p "$RELEASES_DIR"

echo "📦 创建部署包: ${PACKAGE_NAME}"
echo "📁 输出目录: ${RELEASES_DIR}"

# 创建完整包
echo "📦 创建完整部署包..."
tar -czf "${RELEASES_DIR}/${PACKAGE_NAME}-full.tar.gz" \
    --exclude='.git' \
    --exclude='log/*.log' \
    --exclude='*.tar.gz' \
    --exclude='scripts/package.sh' \
    --exclude='build/' \
    --exclude='docker-web-env-v*' \
    .

# 创建最小化包
echo "📦 创建最小化部署包..."
tar -czf "${RELEASES_DIR}/${PACKAGE_NAME}-minimal.tar.gz" \
    docker-compose.yml \
    docker-compose.prod.yml \
    conf/ \
    supervisor/ \
    deploy.sh \
    install.sh \
    scripts/ \
    README.md \
    DEPLOYMENT.md \
    env.example

# 创建仅配置文件包
echo "📦 创建配置文件包..."
tar -czf "${RELEASES_DIR}/${PACKAGE_NAME}-configs.tar.gz" \
    conf/ \
    supervisor/ \
    docker-compose.yml \
    docker-compose.prod.yml

echo "✅ 打包完成！"
echo "📁 生成的文件："
echo "   - ${RELEASES_DIR}/${PACKAGE_NAME}-full.tar.gz (完整包)"
echo "   - ${RELEASES_DIR}/${PACKAGE_NAME}-minimal.tar.gz (最小化包)"
echo "   - ${RELEASES_DIR}/${PACKAGE_NAME}-configs.tar.gz (仅配置文件)"

echo ""
echo "📊 文件大小："
ls -lh "${RELEASES_DIR}/${PACKAGE_NAME}"-*.tar.gz | awk '{print "   - " $9 ": " $5}'

echo ""
echo "🚀 部署说明："
echo "   1. 上传任意一个包到目标服务器"
echo "   2. 解压: tar -xzf ${PACKAGE_NAME}-*.tar.gz"
echo "   3. 运行: ./deploy.sh"
