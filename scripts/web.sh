#!/bin/bash

# Docker Web Environment 一键管理脚本
# 使用方法: ./scripts/web.sh [命令]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示横幅
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                Docker Web Environment Manager                ║"
    echo "║                    Version 1.2.0                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    show_banner
    echo -e "${BLUE}🚀 可用命令:${NC}"
    echo ""
    echo -e "${GREEN}📦 基础管理:${NC}"
    echo "  start     - 启动服务"
    echo "  stop      - 停止服务"
    echo "  restart   - 重启服务"
    echo "  status    - 查看状态"
    echo "  logs      - 查看日志"
    echo "  test      - 测试服务"
    echo "  shell     - 进入容器"
    echo "  clean     - 清理资源"
    echo ""
    echo -e "${YELLOW}⚙️  服务管理:${NC}"
    echo "  nginx     - 重启 Nginx"
    echo "  php       - 重启 PHP-FPM"
    echo "  reload    - 重新加载配置"
    echo "  build     - 重新构建"
    echo ""
    echo -e "${PURPLE}📝 配置管理:${NC}"
    echo "  edit-nginx    - 编辑 Nginx 配置"
    echo "  edit-php      - 编辑 PHP 配置"
    echo "  edit-compose  - 编辑 Docker Compose 配置"
    echo ""
    echo -e "${CYAN}🔍 监控诊断:${NC}"
    echo "  health    - 健康检查"
    echo "  info      - PHP 信息"
    echo "  stats     - 资源统计"
    echo "  check     - 连接检查"
    echo ""
    echo -e "${RED}🛠️  高级功能:${NC}"
    echo "  deploy    - 完整部署"
    echo "  quick     - 快速部署"
    echo "  one       - 一键部署"
    echo "  aliases   - 加载快捷别名"
    echo ""
    echo -e "${BLUE}💡 示例:${NC}"
    echo "  ./web.sh start      # 启动服务"
    echo "  ./web.sh nginx      # 重启 Nginx"
    echo "  ./web.sh edit-nginx # 编辑 Nginx 配置"
    echo "  ./web.sh health     # 健康检查"
}

# 基础管理命令
start_service() {
    echo -e "${GREEN}🚀 启动服务...${NC}"
    ./scripts/manage.sh start
}

stop_service() {
    echo -e "${YELLOW}⏹️  停止服务...${NC}"
    ./scripts/manage.sh stop
}

restart_service() {
    echo -e "${BLUE}🔄 重启服务...${NC}"
    ./scripts/manage.sh restart
}

show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    ./scripts/manage.sh status
}

show_logs() {
    echo -e "${BLUE}📋 服务日志:${NC}"
    ./scripts/manage.sh logs
}

test_service() {
    echo -e "${BLUE}🧪 测试服务...${NC}"
    ./scripts/manage.sh test
}

enter_shell() {
    echo -e "${BLUE}🐚 进入容器...${NC}"
    ./scripts/manage.sh shell
}

clean_resources() {
    echo -e "${YELLOW}🧹 清理资源...${NC}"
    ./scripts/manage.sh clean
}

# 服务管理
restart_nginx() {
    echo -e "${BLUE}🔄 重启 Nginx...${NC}"
    ./manage.sh nginx
}

restart_php() {
    echo -e "${BLUE}🔄 重启 PHP-FPM...${NC}"
    ./manage.sh php
}

reload_config() {
    echo -e "${BLUE}🔄 重新加载配置...${NC}"
    ./manage.sh reload
}

rebuild_service() {
    echo -e "${BLUE}🔨 重新构建...${NC}"
    ./manage.sh build
}

# 配置管理
edit_nginx() {
    echo -e "${BLUE}📝 编辑 Nginx 配置...${NC}"
    nano conf/nginx.conf
    echo -e "${YELLOW}⚠️  配置已修改，使用 './web.sh reload' 重新加载${NC}"
}

edit_php() {
    echo -e "${BLUE}📝 编辑 PHP 配置...${NC}"
    nano conf/php.ini
    echo -e "${YELLOW}⚠️  配置已修改，使用 './web.sh php' 重启 PHP-FPM${NC}"
}

edit_compose() {
    echo -e "${BLUE}📝 编辑 Docker Compose 配置...${NC}"
    nano docker-compose.yml
    echo -e "${YELLOW}⚠️  配置已修改，使用 './web.sh restart' 重启服务${NC}"
}

# 监控诊断
health_check() {
    echo -e "${BLUE}🏥 健康检查...${NC}"
    if curl -s http://localhost:80/health.php | grep -q "OK"; then
        echo -e "${GREEN}✅ 服务健康${NC}"
    else
        echo -e "${RED}❌ 服务异常${NC}"
    fi
}

php_info() {
    echo -e "${BLUE}ℹ️  PHP 信息:${NC}"
    curl -s http://localhost:80/index.php | grep -E "(PHP Version|Server Software)" | head -5
}

show_stats() {
    echo -e "${BLUE}📈 资源统计:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

check_connection() {
    echo -e "${BLUE}🔍 连接检查...${NC}"
    curl -I http://localhost:80/ 2>/dev/null | head -3
}

# 高级功能
full_deploy() {
    echo -e "${BLUE}🚀 完整部署...${NC}"
    ./deploy.sh
}

quick_deploy() {
    echo -e "${BLUE}⚡ 快速部署...${NC}"
    ./quick-deploy.sh
}

one_click_deploy() {
    echo -e "${BLUE}🎯 一键部署...${NC}"
    ./one-click-deploy.sh
}

load_aliases() {
    echo -e "${BLUE}🔗 加载快捷别名...${NC}"
    source ./aliases.sh
}

# 主函数
main() {
    case "${1:-help}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        test)
            test_service
            ;;
        shell)
            enter_shell
            ;;
        clean)
            clean_resources
            ;;
        nginx)
            restart_nginx
            ;;
        php)
            restart_php
            ;;
        reload)
            reload_config
            ;;
        build)
            rebuild_service
            ;;
        edit-nginx)
            edit_nginx
            ;;
        edit-php)
            edit_php
            ;;
        edit-compose)
            edit_compose
            ;;
        health)
            health_check
            ;;
        info)
            php_info
            ;;
        stats)
            show_stats
            ;;
        check)
            check_connection
            ;;
        deploy)
            full_deploy
            ;;
        quick)
            quick_deploy
            ;;
        one)
            one_click_deploy
            ;;
        aliases)
            load_aliases
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
