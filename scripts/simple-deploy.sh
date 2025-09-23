#!/bin/bash

# 简化的远程部署脚本
# 直接开始部署，不进行连接测试

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 读取配置文件
CONFIG_FILE="remote-deploy.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 配置文件不存在: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📋 读取配置文件: $CONFIG_FILE${NC}"
source "$CONFIG_FILE"

# 验证必要参数
if [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ]; then
    echo -e "${RED}❌ 配置文件缺少必要参数: SERVER_IP 或 SERVER_USER${NC}"
    exit 1
fi

# 设置认证参数
if [ "$AUTH_TYPE" = "key" ]; then
    if [ -z "$SSH_KEY_PATH" ]; then
        echo -e "${RED}❌ 配置文件缺少 SSH_KEY_PATH${NC}"
        exit 1
    fi
    # 展开波浪号路径
    key_path="${SSH_KEY_PATH/#\~/$HOME}"
    ssh_cmd="ssh -i $key_path -o StrictHostKeyChecking=no"
    scp_cmd="scp -i $key_path -o StrictHostKeyChecking=no"
else
    echo -e "${RED}❌ 只支持密钥认证${NC}"
    exit 1
fi

# 设置部署包
case $PACKAGE_TYPE in
    full)
        package_name="docker-web-env-v1.4.0-full.tar.gz"
        ;;
    minimal)
        package_name="docker-web-env-v1.4.0-minimal.tar.gz"
        ;;
    configs)
        package_name="docker-web-env-v1.4.0-configs.tar.gz"
        ;;
    *)
        echo -e "${RED}❌ 无效的部署包类型: $PACKAGE_TYPE${NC}"
        exit 1
        ;;
esac

package_path="/home/releases/$package_name"

# 检查部署包是否存在
if [ ! -f "$package_path" ]; then
    echo -e "${RED}❌ 部署包不存在: $package_path${NC}"
    echo -e "${BLUE}请先运行 ./scripts/package.sh 创建部署包${NC}"
    exit 1
fi

# 显示部署信息
echo -e "${YELLOW}📋 部署信息:${NC}"
echo "  服务器: $SERVER_USER@$SERVER_IP"
echo "  认证方式: $AUTH_TYPE"
echo "  部署包: $package_name"
echo "  目标目录: ${TARGET_DIR:-/home/docker-web-env}"
echo ""

# 开始部署
echo -e "${BLUE}🚀 开始远程部署...${NC}"

# 1. 上传部署包
echo -e "${BLUE}📦 上传部署包...${NC}"
$scp_cmd "$package_path" "$SERVER_USER@$SERVER_IP:/tmp/"

# 2. 解压部署包
echo -e "${BLUE}📦 解压部署包...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "cd /tmp && tar -xzf $package_name"

# 3. 移动到目标目录
echo -e "${BLUE}📁 移动到目标目录...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "cd /tmp && sudo mv docker-web-env /home/ && cd /home/docker-web-env"

# 4. 设置执行权限
echo -e "${BLUE}🔐 设置执行权限...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "cd /home/docker-web-env && sudo chmod +x *.sh scripts/*.sh"

# 5. 运行部署脚本
echo -e "${BLUE}🚀 运行部署脚本...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "cd /home/docker-web-env && ./deploy.sh"

# 6. 检查部署状态
echo -e "${BLUE}🔍 检查部署状态...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "cd /home/docker-web-env && docker compose ps"

# 7. 清理临时文件
echo -e "${BLUE}🧹 清理临时文件...${NC}"
$ssh_cmd "$SERVER_USER@$SERVER_IP" "rm -f /tmp/$package_name"

echo -e "${GREEN}✅ 远程部署完成！${NC}"
echo -e "${BLUE}🌐 访问地址: http://$SERVER_IP:80/${NC}"
