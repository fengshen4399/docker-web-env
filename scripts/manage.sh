#!/bin/bash

# Docker Web Environment 管理脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Docker Web Environment 管理脚本${NC}"
    echo "=================================="
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  start      - 启动服务"
    echo "  stop       - 停止服务"
    echo "  restart    - 重启服务"
    echo "  status     - 查看服务状态"
    echo "  logs       - 查看日志"
    echo "  nginx      - 重启 Nginx"
    echo "  php        - 重启 PHP-FPM"
    echo "  reload     - 重新加载配置"
    echo "  build      - 重新构建镜像"
    echo "  shell      - 进入容器"
    echo "  test       - 测试服务"
    echo "  clean      - 清理资源"
    echo "  fix-perms  - 修复权限"
    echo "  help       - 显示帮助"
}

# 启动服务
start_service() {
    echo -e "${GREEN}🚀 启动服务...${NC}"
    docker compose up -d
    echo -e "${GREEN}✅ 服务启动完成${NC}"
}

# 停止服务
stop_service() {
    echo -e "${YELLOW}⏹️  停止服务...${NC}"
    docker compose down
    echo -e "${YELLOW}✅ 服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo -e "${BLUE}🔄 重启服务...${NC}"
    docker compose restart
    echo -e "${GREEN}✅ 服务重启完成${NC}"
}

# 查看服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    docker compose ps
    echo ""
    echo -e "${BLUE}📈 资源使用:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 服务日志:${NC}"
    docker compose logs --tail=50 -f
}

# 重启 Nginx
restart_nginx() {
    echo -e "${BLUE}🔄 重启 Nginx...${NC}"
    docker compose exec web supervisorctl restart nginx
    echo -e "${GREEN}✅ Nginx 重启完成${NC}"
}

# 重启 PHP-FPM
restart_php() {
    echo -e "${BLUE}🔄 重启 PHP-FPM...${NC}"
    docker compose exec web supervisorctl restart php-fpm
    echo -e "${GREEN}✅ PHP-FPM 重启完成${NC}"
}

# 重新加载配置
reload_config() {
    echo -e "${BLUE}🔄 重新加载配置...${NC}"
    docker compose exec web nginx -s reload
    docker compose exec web supervisorctl restart php-fpm
    echo -e "${GREEN}✅ 配置重新加载完成${NC}"
}

# 重新构建镜像
rebuild_image() {
    echo -e "${BLUE}🔨 重新构建镜像...${NC}"
    docker compose build --no-cache
    docker compose up -d
    echo -e "${GREEN}✅ 镜像重新构建完成${NC}"
}

# 进入容器
enter_shell() {
    echo -e "${BLUE}🐚 进入容器...${NC}"
    docker compose exec web bash
}

# 测试服务
test_service() {
    echo -e "${BLUE}🧪 测试服务...${NC}"
    
    # 测试健康检查
    echo "测试健康检查..."
    if curl -s http://localhost:80/health.php | grep -q "OK"; then
        echo -e "${GREEN}✅ 健康检查通过${NC}"
    else
        echo -e "${RED}❌ 健康检查失败${NC}"
    fi
    
    # 测试主页
    echo "测试主页..."
    if curl -s http://localhost:80/ | grep -q "Hello from PHP"; then
        echo -e "${GREEN}✅ 主页访问正常${NC}"
    else
        echo -e "${RED}❌ 主页访问失败${NC}"
    fi
    
    # 测试 PHP 信息
    echo "测试 PHP 信息..."
    if curl -s http://localhost:80/index.php | grep -q "PHP Version"; then
        echo -e "${GREEN}✅ PHP 信息页面正常${NC}"
    else
        echo -e "${RED}❌ PHP 信息页面失败${NC}"
    fi
}

# 清理资源
clean_resources() {
    echo -e "${YELLOW}🧹 清理 Docker 资源...${NC}"
    
    # 停止并删除容器
    docker compose down -v
    
    # 删除未使用的镜像
    docker image prune -f
    
    # 删除未使用的网络
    docker network prune -f
    
    # 删除未使用的卷
    docker volume prune -f
    
    echo -e "${GREEN}✅ 资源清理完成${NC}"
}

# 修复权限
fix_permissions() {
    echo -e "${BLUE}🔧 修复应用目录权限...${NC}"
    
    # 创建应用运行时目录（如果不存在）
    echo -e "${YELLOW}📁 检查应用目录...${NC}"
    if [ ! -d "/home/app/default/runtime" ]; then
        echo -e "${YELLOW}创建 runtime 目录...${NC}"
        sudo mkdir -p /home/app/default/runtime/logs
        sudo mkdir -p /home/app/default/runtime/cache
        sudo mkdir -p /home/app/default/runtime/temp
    else
        echo -e "${GREEN}✓ runtime 目录已存在${NC}"
        # 确保子目录存在
        sudo mkdir -p /home/app/default/runtime/logs
        sudo mkdir -p /home/app/default/runtime/cache
        sudo mkdir -p /home/app/default/runtime/temp
    fi
    
    # 设置目录权限
    echo -e "${YELLOW}🔐 设置目录权限...${NC}"
    sudo chown -R www-data:www-data /home/app/default
    sudo chmod -R 755 /home/app/default
    
    # 设置运行时目录为可写
    sudo chmod -R 777 /home/app/default/runtime
    
    # 测试权限
    echo -e "${YELLOW}🧪 测试权限...${NC}"
    if sudo -u www-data touch /home/app/default/runtime/logs/test.log 2>/dev/null; then
        echo -e "${GREEN}✅ 应用日志目录权限正常${NC}"
        sudo rm -f /home/app/default/runtime/logs/test.log
    else
        echo -e "${RED}❌ 应用日志目录权限有问题${NC}"
        echo -e "${YELLOW}💡 提示: 请检查容器内的用户配置${NC}"
    fi
    
    echo -e "${GREEN}✅ 权限修复完成${NC}"
    echo -e "${BLUE}📁 应用目录: /home/app/default${NC}"
    echo -e "${BLUE}📁 运行时目录: /home/app/default/runtime${NC}"
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
            rebuild_image
            ;;
        shell)
            enter_shell
            ;;
        test)
            test_service
            ;;
        clean)
            clean_resources
            ;;
        fix-perms)
            fix_permissions
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
