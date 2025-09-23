#!/bin/bash

# 快速修复脚本 - 解决当前问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 快速修复脚本${NC}"
echo "=================="

# 1. 修复 web.sh 脚本路径问题
echo -e "${YELLOW}1. 检查 web.sh 脚本...${NC}"
if [ -f "./scripts/web.sh" ]; then
    echo -e "${GREEN}✓ web.sh 脚本存在${NC}"
else
    echo -e "${RED}✗ web.sh 脚本不存在${NC}"
    exit 1
fi

# 2. 修复 manage.sh 脚本路径问题
echo -e "${YELLOW}2. 检查 manage.sh 脚本...${NC}"
if [ -f "./scripts/manage.sh" ]; then
    echo -e "${GREEN}✓ manage.sh 脚本存在${NC}"
else
    echo -e "${RED}✗ manage.sh 脚本不存在${NC}"
    exit 1
fi

# 3. 修复应用目录权限
echo -e "${YELLOW}3. 修复应用目录权限...${NC}"
# 创建应用运行时目录（如果不存在）
if [ ! -d "/home/app/default/runtime" ]; then
    echo -e "${YELLOW}创建 runtime 目录...${NC}"
    sudo mkdir -p /home/app/default/runtime/logs
    sudo mkdir -p /home/app/default/runtime/cache
    sudo mkdir -p /home/app/default/runtime/temp
else
    echo -e "${GREEN}✓ runtime 目录已存在${NC}"
    sudo mkdir -p /home/app/default/runtime/logs
    sudo mkdir -p /home/app/default/runtime/cache
    sudo mkdir -p /home/app/default/runtime/temp
fi

# 设置权限
sudo chown -R www-data:www-data /home/app/default
sudo chmod -R 755 /home/app/default
sudo chmod -R 777 /home/app/default/runtime

echo -e "${GREEN}✓ 应用目录权限已修复${NC}"

# 4. 测试权限
echo -e "${YELLOW}4. 测试权限...${NC}"
if sudo -u www-data touch /home/app/default/runtime/logs/test.log 2>/dev/null; then
    echo -e "${GREEN}✓ 日志目录权限正常${NC}"
    sudo rm -f /home/app/default/runtime/logs/test.log
else
    echo -e "${RED}✗ 日志目录权限仍有问题${NC}"
fi

# 5. 重启服务
echo -e "${YELLOW}5. 重启服务...${NC}"
docker compose restart

echo -e "${GREEN}✅ 快速修复完成！${NC}"
echo ""
echo -e "${BLUE}💡 现在可以使用以下命令：${NC}"
echo "  sudo web reload    # 重新加载配置"
echo "  sudo web restart   # 重启服务"
echo "  sudo web fix-perms # 修复权限"
echo ""
echo -e "${BLUE}📁 应用目录结构：${NC}"
echo "  /home/app/default/          # 应用根目录"
echo "  /home/app/default/runtime/  # 运行时目录（已包含在应用挂载中）"
echo "    ├── logs/                 # 应用日志"
echo "    ├── cache/                # 缓存文件"
echo "    └── temp/                 # 临时文件"
