#!/bin/bash

# 安装全局快捷命令脚本
# 将快捷命令添加到系统 PATH 中

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 安装全局快捷命令...${NC}"

# 获取当前目录
CURRENT_DIR=$(pwd)
WEB_SCRIPT="$CURRENT_DIR/scripts/web.sh"

# 检查脚本是否存在
if [ ! -f "$WEB_SCRIPT" ]; then
    echo -e "${RED}❌ 未找到 scripts/web.sh 脚本${NC}"
    exit 1
fi

# 创建全局命令脚本
sudo tee /usr/local/bin/web > /dev/null << EOF
#!/bin/bash
# Docker Web Environment 全局快捷命令
cd "$CURRENT_DIR"
./scripts/web.sh "\$@"
EOF

# 设置执行权限
sudo chmod +x /usr/local/bin/web

# 创建别名安装脚本
sudo tee /usr/local/bin/web-aliases > /dev/null << EOF
#!/bin/bash
# 加载 Docker Web Environment 快捷别名
cd "$CURRENT_DIR"
source ./scripts/aliases.sh
EOF

# 设置执行权限
sudo chmod +x /usr/local/bin/web-aliases

echo -e "${GREEN}✅ 全局快捷命令安装完成！${NC}"
echo ""
echo -e "${BLUE}🚀 现在您可以在任何目录使用以下命令:${NC}"
echo "  web start      # 启动服务"
echo "  web stop       # 停止服务"
echo "  web restart    # 重启服务"
echo "  web status     # 查看状态"
echo "  web nginx      # 重启 Nginx"
echo "  web php        # 重启 PHP-FPM"
echo "  web health     # 健康检查"
echo "  web help       # 查看帮助"
echo ""
echo -e "${YELLOW}💡 加载快捷别名:${NC}"
echo "  web-aliases    # 加载所有快捷别名"
echo "  source <(web-aliases)  # 在当前 shell 中加载别名"
echo ""
echo -e "${GREEN}🎉 安装完成！现在可以在任何地方使用 'web' 命令了！${NC}"
