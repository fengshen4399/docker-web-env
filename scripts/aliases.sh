#!/bin/bash

# Docker Web Environment 快捷命令别名
# 使用方法: source ./aliases.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 加载快捷命令别名...${NC}"

# 基础管理命令
alias web-start='./manage.sh start'
alias web-stop='./manage.sh stop'
alias web-restart='./manage.sh restart'
alias web-status='./manage.sh status'
alias web-logs='./manage.sh logs'
alias web-test='./manage.sh test'
alias web-shell='./manage.sh shell'
alias web-clean='./manage.sh clean'

# 服务管理
alias nginx-restart='./manage.sh nginx'
alias php-restart='./manage.sh php'
alias web-reload='./manage.sh reload'
alias web-build='./manage.sh build'

# Docker 快捷命令
alias d-ps='docker compose ps'
alias d-logs='docker compose logs'
alias d-up='docker compose up -d'
alias d-down='docker compose down'
alias d-build='docker compose build'
alias d-restart='docker compose restart'

# 容器操作
alias d-exec='docker compose exec web'
alias d-bash='docker compose exec web bash'
alias d-nginx='docker compose exec web nginx -s reload'
alias d-php='docker compose exec web supervisorctl restart php-fpm'

# 日志查看
alias logs-nginx='docker compose exec web tail -f /var/log/access.log'
alias logs-php='docker compose exec web tail -f /var/log/php-fpm-error.log'
alias logs-all='docker compose logs -f'

# 文件操作
alias web-edit-nginx='nano conf/nginx.conf'
alias web-edit-php='nano conf/php.ini'
alias web-edit-compose='nano docker-compose.yml'

# 测试命令
alias web-health='curl -s http://localhost:80/health.php'
alias web-info='curl -s http://localhost:80/index.php | head -20'
alias web-check='curl -I http://localhost:80/'

# 系统信息
alias web-stats='docker stats --no-stream'
alias web-disk='df -h'
alias web-mem='free -h'

# 部署相关
alias web-deploy='./deploy.sh'
alias web-quick='./quick-deploy.sh'
alias web-one='./one-click-deploy.sh'

# 显示所有别名
alias web-help='echo -e "${BLUE}可用快捷命令:${NC}"; echo "基础管理: web-start, web-stop, web-restart, web-status, web-logs, web-test, web-shell, web-clean"; echo "服务管理: nginx-restart, php-restart, web-reload, web-build"; echo "Docker命令: d-ps, d-logs, d-up, d-down, d-build, d-restart"; echo "容器操作: d-exec, d-bash, d-nginx, d-php"; echo "日志查看: logs-nginx, logs-php, logs-all"; echo "文件编辑: web-edit-nginx, web-edit-php, web-edit-compose"; echo "测试命令: web-health, web-info, web-check"; echo "系统信息: web-stats, web-disk, web-mem"; echo "部署相关: web-deploy, web-quick, web-one"'

echo -e "${GREEN}✅ 快捷命令别名加载完成！${NC}"
echo -e "${BLUE}💡 使用 'web-help' 查看所有可用命令${NC}"
echo -e "${YELLOW}📝 使用 'source ./aliases.sh' 重新加载别名${NC}"
