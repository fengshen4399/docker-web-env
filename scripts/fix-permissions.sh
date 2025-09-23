#!/bin/bash

# 修复日志目录权限脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 修复日志目录权限...${NC}"

# 创建必要的目录
echo -e "${YELLOW}📁 创建目录...${NC}"
sudo mkdir -p /home/app/default/runtime
sudo mkdir -p /home/app/default/runtime/logs
sudo mkdir -p /home/app/default/runtime/cache
sudo mkdir -p /home/app/default/runtime/temp

# 设置目录权限
echo -e "${YELLOW}🔐 设置目录权限...${NC}"
sudo chown -R www-data:www-data /home/app/default/runtime
sudo chmod -R 755 /home/app/default/runtime

# 设置日志目录特殊权限（可写）
sudo chmod -R 777 /home/app/default/runtime/logs
sudo chmod -R 777 /home/app/default/runtime/cache
sudo chmod -R 777 /home/app/default/runtime/temp

# 确保主目录权限正确
sudo chown -R www-data:www-data /home/app/default
sudo chmod -R 755 /home/app/default

# 创建测试文件验证权限
echo -e "${YELLOW}🧪 测试权限...${NC}"
sudo -u www-data touch /home/app/default/runtime/logs/test.log 2>/dev/null && echo -e "${GREEN}✓ 日志目录权限正常${NC}" || echo -e "${RED}✗ 日志目录权限有问题${NC}"

# 显示目录信息
echo -e "${BLUE}📊 目录信息:${NC}"
ls -la /home/app/default/ | grep runtime || echo "runtime 目录不存在"
ls -la /home/app/default/runtime/ 2>/dev/null || echo "runtime 目录为空"

echo -e "${GREEN}✅ 权限修复完成！${NC}"
echo -e "${BLUE}💡 提示: 如果仍有权限问题，请检查应用的用户配置${NC}"
