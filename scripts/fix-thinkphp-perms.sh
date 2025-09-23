#!/bin/bash

# ThinkPHP 权限修复脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 ThinkPHP 权限修复脚本${NC}"
echo "=============================="

# 检查容器是否运行
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}❌ 容器未运行，请先启动容器${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 创建 ThinkPHP 完整目录结构...${NC}"

# 在容器内创建完整的 ThinkPHP 目录结构
docker compose exec web mkdir -p /www/runtime/log
docker compose exec web mkdir -p /www/runtime/cache
docker compose exec web mkdir -p /www/runtime/temp
docker compose exec web mkdir -p /www/runtime/session
docker compose exec web mkdir -p /www/runtime/compile
docker compose exec web mkdir -p /www/runtime/logs

echo -e "${YELLOW}🔐 设置目录权限...${NC}"

# 设置权限
docker compose exec web chmod -R 777 /www/runtime
docker compose exec web chown -R www-data:www-data /www/runtime

# 确保整个应用目录权限正确
docker compose exec web chown -R www-data:www-data /www
docker compose exec web chmod -R 755 /www
docker compose exec web chmod -R 777 /www/runtime

echo -e "${YELLOW}🧪 测试权限...${NC}"

# 测试各个目录的写入权限
test_dirs=("log" "cache" "temp" "session" "compile" "logs")
for dir in "${test_dirs[@]}"; do
    if docker compose exec web touch /www/runtime/$dir/test.log 2>/dev/null; then
        echo -e "${GREEN}✓ /www/runtime/$dir 权限正常${NC}"
        docker compose exec web rm -f /www/runtime/$dir/test.log
    else
        echo -e "${RED}✗ /www/runtime/$dir 权限有问题${NC}"
    fi
done

echo -e "${YELLOW}📊 显示目录结构...${NC}"
docker compose exec web ls -la /www/runtime/

echo -e "${GREEN}✅ ThinkPHP 权限修复完成！${NC}"
echo ""
echo -e "${BLUE}💡 现在 ThinkPHP 应该可以正常写入日志了${NC}"
echo -e "${BLUE}📁 日志目录: /www/runtime/log/${NC}"
echo -e "${BLUE}📁 缓存目录: /www/runtime/cache/${NC}"
echo -e "${BLUE}📁 临时目录: /www/runtime/temp/${NC}"
