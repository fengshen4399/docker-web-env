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
    echo "  cron       - 重新加载定时任务"
    echo "  build      - 重新构建镜像"
    echo "  shell      - 进入容器"
    echo "  test       - 测试服务"
    echo "  clean      - 清理资源"
    echo "  fix-perms  - 修复权限"
    echo "  daemon     - 守护进程管理 (容器内supervisor进程)"
    echo "  queue      - 重启所有队列进程"
    echo "  supervisor - 显示supervisor状态"
    echo "  processes  - 显示容器内所有进程"
    echo "  monitor    - 详细资源监控和分析"
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
    
    # 检查高CPU使用率
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" my_web 2>/dev/null | sed 's/%//')
    if [ -n "$cpu_usage" ] && (( $(echo "$cpu_usage > 100" | bc -l 2>/dev/null || echo "0") )); then
        echo ""
        echo -e "${RED}⚠️  检测到高CPU使用率 ($cpu_usage%)${NC}"
        echo -e "${YELLOW}📋 容器内高CPU进程分析:${NC}"
        echo "----------------------------------------"
        docker exec my_web ps aux --sort=-%cpu | head -10 2>/dev/null || echo "无法获取进程信息"
        echo "----------------------------------------"
        
        echo ""
        echo -e "${BLUE}💡 建议检查以下项目:${NC}"
        echo "  1. 队列进程是否正常 - 使用: $0 supervisor"
        echo "  2. 应用日志错误信息 - 使用: $0 logs"
        echo "  3. 重启队列进程 - 使用: $0 queue"
    fi
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

# 重新加载定时任务
reload_cron() {
    echo -e "${BLUE}🔄 重新加载定时任务...${NC}"
    
    # 检查配置文件是否存在
    if [ ! -f "crontab-template.conf" ]; then
        echo -e "${RED}❌ 配置文件 crontab-template.conf 不存在${NC}"
        return 1
    fi
    
    # 显示即将加载的配置
    echo -e "${YELLOW}📋 即将加载的定时任务配置:${NC}"
    grep -v "^#" crontab-template.conf | grep -v "^$" || echo "无有效任务配置"
    echo ""
    
    # 重新加载定时任务
    echo -e "${BLUE}🔄 重载容器内定时任务...${NC}"
    sudo docker exec my_web cron-manager reload
    
    echo -e "${GREEN}✅ 定时任务重新加载完成${NC}"
    
    # 显示当前状态
    echo -e "${BLUE}📊 当前定时任务状态:${NC}"
    sudo docker exec my_web cron-manager status | grep -v "^#" | grep -v "^$" || echo "无活动任务"
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

# 守护进程管理
daemon_management() {
    echo -e "${BLUE}🔧 容器守护进程管理 (${GREEN}my_web${BLUE})${NC}"
    echo "=========================================="
    
    if [ $# -eq 0 ]; then
        echo "守护进程管理选项:"
        echo "  -s, --status     显示所有进程状态"
        echo "  -a, --all        重启所有进程"
        echo "  -q, --queue      重启队列进程"
        echo "  -w, --web        重启Web服务"
        echo "  -r <name>        重启指定进程"
        echo "  -f <name>        强制重启指定进程"
        echo "  -h, --help       显示帮助"
        echo ""
        echo "示例:"
        echo "  $0 daemon -s          显示进程状态"
        echo "  $0 daemon -r nginx     重启nginx"
        echo "  $0 daemon -q           重启所有队列"
        return
    fi
    
    # 调用专门的守护进程重启脚本
    if [ -f "/home/docker-web-env/scripts/restart-daemon.sh" ]; then
        bash /home/docker-web-env/scripts/restart-daemon.sh "$@"
    else
        echo -e "${RED}❌ 守护进程重启脚本不存在${NC}"
        echo "请确保 /home/docker-web-env/scripts/restart-daemon.sh 文件存在"
        exit 1
    fi
}

# 重启队列进程
restart_queues() {
    echo -e "${BLUE}🔄 重启所有队列进程...${NC}"
    
    # 调用专门的守护进程重启脚本重启队列
    if [ -f "/home/docker-web-env/scripts/restart-daemon.sh" ]; then
        /home/docker-web-env/scripts/restart-daemon.sh --queue
    else
        echo -e "${RED}❌ 守护进程重启脚本不存在${NC}"
        echo "请确保 /home/docker-web-env/scripts/restart-daemon.sh 文件存在"
        exit 1
    fi
}

# 详细资源监控
resource_monitor() {
    echo -e "${BLUE}📊 详细资源监控分析 (容器: my_web)${NC}"
    echo "=============================================="
    
    # 1. 容器资源统计
    echo -e "${GREEN}📈 容器资源使用情况:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" my_web
    
    # 2. 获取CPU使用率进行分析
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" my_web 2>/dev/null | sed 's/%//')
    echo ""
    
    if [ -n "$cpu_usage" ]; then
        if (( $(echo "$cpu_usage > 150" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${RED}🚨 CPU使用率极高 ($cpu_usage%) - 紧急情况${NC}"
        elif (( $(echo "$cpu_usage > 100" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}⚠️  CPU使用率过高 ($cpu_usage%) - 需要关注${NC}"
        elif (( $(echo "$cpu_usage > 50" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}💡 CPU使用率较高 ($cpu_usage%) - 正常范围内${NC}"
        else
            echo -e "${GREEN}✅ CPU使用率正常 ($cpu_usage%)${NC}"
        fi
    fi
    
    # 3. 容器内进程分析
    echo ""
    echo -e "${BLUE}🔍 TOP 10 高CPU进程:${NC}"
    echo "----------------------------------------"
    printf "%-10s %-8s %-8s %-50s\n" "USER" "PID" "%CPU" "COMMAND"
    echo "----------------------------------------"
    docker exec my_web ps aux --sort=-%cpu 2>/dev/null | head -11 | tail -10 || echo "无法获取进程信息"
    
    # 4. 内存使用分析
    echo ""
    echo -e "${BLUE}🧠 内存使用详情:${NC}"
    echo "----------------------------------------"
    docker exec my_web free -h 2>/dev/null || echo "无法获取内存信息"
    
    # 5. 队列进程状态
    echo ""
    echo -e "${BLUE}🔄 队列进程状态:${NC}"
    echo "----------------------------------------"
    docker exec my_web supervisorctl status 2>/dev/null | grep -E "(default|order_|usdt_)" || echo "无法获取队列进程状态"
    
    # 6. 系统负载
    echo ""
    echo -e "${BLUE}⚖️  系统负载:${NC}"
    echo "----------------------------------------"
    docker exec my_web uptime 2>/dev/null || echo "无法获取系统负载"
    
    # 7. 网络连接统计
    echo ""
    echo -e "${BLUE}🌐 网络连接统计:${NC}"
    echo "----------------------------------------"
    docker exec my_web netstat -an 2>/dev/null | awk '/^tcp/ {count[$6]++} END {for (state in count) print state, count[state]}' | sort -k2 -nr || echo "无法获取网络统计"
    
    # 8. 建议和操作
    echo ""
    echo -e "${BLUE}💡 性能优化建议:${NC}"
    echo "========================================="
    
    if [ -n "$cpu_usage" ] && (( $(echo "$cpu_usage > 100" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${YELLOW}🔧 高CPU使用率解决建议:${NC}"
        echo "  1. 重启队列进程: $0 queue"
        echo "  2. 检查应用日志: $0 logs"
        echo "  3. 重启所有服务: $0 restart"
        echo "  4. 查看详细进程: $0 processes"
        echo "  5. 强制重启容器: docker compose restart"
    else
        echo -e "${GREEN}✅ 系统运行正常，无需特别操作${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔄 实时监控 (按 Ctrl+C 停止):${NC}"
    echo "使用命令: docker stats my_web"
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
    fi
    
    # 创建 ThinkPHP 完整目录结构
    echo -e "${YELLOW}📁 创建 ThinkPHP 目录结构...${NC}"
    sudo mkdir -p /home/app/default/runtime/log
    sudo mkdir -p /home/app/default/runtime/cache
    sudo mkdir -p /home/app/default/runtime/temp
    sudo mkdir -p /home/app/default/runtime/session
    sudo mkdir -p /home/app/default/runtime/compile
    sudo mkdir -p /home/app/default/runtime/logs
    
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
        cron)
            reload_cron
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
        daemon)
            shift  # 移除 daemon 参数
            daemon_management "$@"
            ;;
        queue)
            restart_queues
            ;;
        supervisor)
            echo -e "${BLUE}📊 Supervisor 进程状态 (容器: my_web):${NC}"
            if [ -f "/home/docker-web-env/scripts/restart-daemon.sh" ]; then
                bash /home/docker-web-env/scripts/restart-daemon.sh -s
            else
                echo -e "${RED}❌ 守护进程脚本不存在${NC}"
            fi
            ;;
        processes)
            echo -e "${BLUE}📊 容器内所有进程:${NC}"
            sudo docker exec my_web supervisorctl status 2>/dev/null || echo -e "${RED}❌ 无法连接到容器${NC}"
            ;;
        monitor)
            resource_monitor
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
