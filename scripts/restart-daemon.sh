#!/bin/bash

# 重启守护进程脚本
# 作者: Docker Web Environment
# 功能: 提供重启supervisor管理的守护进程的功能（支持Docker容器）

# 容器配置
CONTAINER_NAME="my_web"

# 颜色定义
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查容器是否运行的函数
check_container() {
    if ! sudo docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log_error "容器 ${CONTAINER_NAME} 未运行"
        log_info "请先启动容器: docker-compose up -d"
        return 1
    fi
    return 0
}

# 检查容器内supervisor是否运行
check_supervisor() {
    if ! check_container; then
        return 1
    fi
    
    # 检查supervisorctl命令是否可用
    if ! sudo docker exec "${CONTAINER_NAME}" which supervisorctl > /dev/null 2>&1; then
        log_error "容器内未找到 supervisorctl 命令"
        return 1
    fi
    
    # 检查supervisor守护进程是否运行 - 使用多种方法检测
    local supervisor_running=false
    
    # 方法1: 检查进程名
    if sudo docker exec "${CONTAINER_NAME}" pgrep -f "supervisord" > /dev/null 2>&1; then
        supervisor_running=true
    fi
    
    # 方法2: 检查进程树中的supervisord
    if [ "$supervisor_running" = false ] && sudo docker exec "${CONTAINER_NAME}" ps aux | grep -q "[s]upervisord" 2>/dev/null; then
        supervisor_running=true
    fi
    
    # 方法3: 尝试执行supervisorctl version
    if [ "$supervisor_running" = false ] && sudo docker exec "${CONTAINER_NAME}" supervisorctl version > /dev/null 2>&1; then
        supervisor_running=true
    fi
    
    if [ "$supervisor_running" = false ]; then
        log_error "容器内 Supervisor 守护进程未运行，请先启动 supervisord"
        log_info "可以尝试在容器内执行: supervisord -c /etc/supervisor/supervisord.conf"
        log_info "或者重启容器: docker compose restart"
        return 1
    fi
    
    return 0
}

# 执行容器内supervisorctl命令
# 在容器中执行supervisorctl命令的包装函数
supervisorctl_exec() {
    sudo docker exec "${CONTAINER_NAME}" supervisorctl "$@"
}

# 显示所有守护进程状态
show_status() {
    log_info "当前守护进程状态 (容器: ${CONTAINER_NAME}):"
    echo "=================================="
    
    # 尝试获取进程状态，如果失败则显示错误信息
    if supervisorctl_exec status 2>/dev/null; then
        echo "=================================="
        
        # 显示详细的进程用户信息
        echo ""
        log_info "进程详细信息 (包含运行用户):"
        echo "--------------------------------"
        printf "%-30s %-10s %-8s %s\n" "进程名" "用户" "PID" "命令"
        echo "--------------------------------"
        
        # 获取所有supervisor管理的进程
        local processes=$(supervisorctl_exec status 2>/dev/null | awk '{print $1}' | grep -v "^$")
        
        for process in $processes; do
            # 获取进程的PID
            local pid=$(supervisorctl_exec status "$process" 2>/dev/null | awk '{print $4}' | sed 's/,$//')
            
            if [ -n "$pid" ] && [ "$pid" != "EXITED" ] && [ "$pid" != "STOPPED" ]; then
                # 通过PID获取进程的用户和命令信息
                local process_info=$(sudo docker exec "${CONTAINER_NAME}" ps -p "$pid" -o user,pid,comm --no-headers 2>/dev/null || true)
                
                if [ -n "$process_info" ]; then
                    local user=$(echo "$process_info" | awk '{print $1}')
                    local cmd=$(echo "$process_info" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}')
                    printf "%-30s %-10s %-8s %s\n" "$process" "$user" "$pid" "$cmd"
                else
                    printf "%-30s %-10s %-8s %s\n" "$process" "N/A" "$pid" "进程信息获取失败"
                fi
            else
                printf "%-30s %-10s %-8s %s\n" "$process" "N/A" "N/A" "进程未运行"
            fi
        done
        echo "=================================="
    else
        log_warning "无法通过 supervisorctl 获取进程状态"
        echo "尝试显示容器内进程信息..."
        
        # 显示容器内的进程信息作为替代
        echo "容器内运行的进程:"
        if sudo docker exec "${CONTAINER_NAME}" ps aux 2>/dev/null | grep -E "(supervisord|nginx|php-fpm|python|queue)" | grep -v grep; then
            echo "--------------------------------"
        else
            log_error "无法获取容器内进程信息"
        fi
        echo "=================================="
        
        # 提供诊断信息
        log_info "诊断信息:"
        echo "1. 检查容器是否正常运行..."
        if sudo docker exec "${CONTAINER_NAME}" echo "容器可访问" 2>/dev/null; then
            echo "   ✓ 容器正常运行"
        else
            echo "   ✗ 容器无法访问"
        fi
        
        echo "2. 检查 supervisord 进程..."
        if sudo docker exec "${CONTAINER_NAME}" pgrep -f supervisord >/dev/null 2>&1; then
            echo "   ✓ supervisord 进程存在"
        else
            echo "   ✗ supervisord 进程不存在"
        fi
        
        echo "3. 检查 supervisor 配置..."
        if sudo docker exec "${CONTAINER_NAME}" test -f /etc/supervisor/supervisord.conf 2>/dev/null; then
            echo "   ✓ supervisor 配置文件存在"
        else
            echo "   ✗ supervisor 配置文件不存在"
        fi
    fi
}

# 显示进程用户详情
show_process_users() {
    log_info "显示所有进程的用户信息 (容器: ${CONTAINER_NAME}):"
    echo "=================================="
    
    # 显示格式化的进程信息
    printf "%-15s %-10s %-8s %-50s\n" "用户" "PID" "%CPU" "命令"
    echo "--------------------------------"
    
    # 显示所有相关进程
    sudo docker exec "${CONTAINER_NAME}" ps aux 2>/dev/null | grep -E "(supervisord|nginx|php-fpm|queue|cron)" | grep -v grep | \
    while IFS= read -r line; do
        printf "%-15s %-10s %-8s %-50s\n" \
            "$(echo "$line" | awk '{print $1}')" \
            "$(echo "$line" | awk '{print $2}')" \
            "$(echo "$line" | awk '{print $3}')" \
            "$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}' | cut -c1-45)..."
    done
    
    echo "=================================="
}

# 重启指定守护进程
restart_daemon() {
    local daemon_name="$1"
    
    if [ -z "$daemon_name" ]; then
        log_error "请指定要重启的守护进程名称"
        return 1
    fi
    
    log_info "正在重启守护进程: $daemon_name"
    
    # 检查进程是否存在
    if ! supervisorctl_exec status "$daemon_name" &>/dev/null; then
        log_error "守护进程 '$daemon_name' 不存在"
        return 1
    fi
    
    # 重启进程
    if supervisorctl_exec restart "$daemon_name"; then
        log_success "守护进程 '$daemon_name' 重启成功"
        
        # 等待3秒后检查状态
        sleep 3
        local status=$(supervisorctl_exec status "$daemon_name" | awk '{print $2}')
        if [ "$status" = "RUNNING" ]; then
            log_success "守护进程 '$daemon_name' 运行正常"
        else
            log_warning "守护进程 '$daemon_name' 状态异常: $status"
        fi
    else
        log_error "重启守护进程 '$daemon_name' 失败"
        return 1
    fi
}

# 重启所有守护进程
restart_all() {
    log_info "正在重启所有守护进程 (容器: ${CONTAINER_NAME})..."
    
    if supervisorctl_exec restart all; then
        log_success "所有守护进程重启完成"
        sleep 5
        show_status
    else
        log_error "重启所有守护进程失败"
        return 1
    fi
}

# 重启特定类型的进程
restart_queue_workers() {
    log_info "正在重启所有队列工作进程..."
    
    local queue_processes=("default:*" "order_notify:*" "order_query:*" "usdt_transfer:*")
    
    for process in "${queue_processes[@]}"; do
        if supervisorctl_exec status "$process" &>/dev/null; then
            restart_daemon "$process"
        else
            log_warning "队列进程 '$process' 未配置或不存在"
        fi
    done
}

# 重启Web服务
restart_web_services() {
    log_info "正在重启Web服务..."
    
    local web_services=("nginx" "php-fpm")
    
    for service in "${web_services[@]}"; do
        if supervisorctl_exec status "$service" &>/dev/null; then
            restart_daemon "$service"
        else
            log_warning "Web服务 '$service' 未配置或不存在"
        fi
    done
}

# 强制停止并重启进程
force_restart() {
    local daemon_name="$1"
    
    if [ -z "$daemon_name" ]; then
        log_error "请指定要强制重启的守护进程名称"
        return 1
    fi
    
    log_warning "正在强制重启守护进程: $daemon_name"
    
    # 先停止
    supervisorctl_exec stop "$daemon_name"
    sleep 2
    
    # 再启动
    if supervisorctl_exec start "$daemon_name"; then
        log_success "守护进程 '$daemon_name' 强制重启成功"
    else
        log_error "强制重启守护进程 '$daemon_name' 失败"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Docker容器守护进程重启脚本"
    echo "目标容器: ${CONTAINER_NAME}"
    echo ""
    echo "用法: $0 [选项] [进程名]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -s, --status            显示所有守护进程状态"
    echo "  -u, --users             显示所有进程的用户信息"
    echo "  -a, --all               重启所有守护进程"
    echo "  -q, --queue             重启所有队列工作进程"
    echo "  -w, --web               重启Web服务(nginx, php-fpm)"
    echo "  -f, --force <进程名>     强制重启指定进程"
    echo "  -r, --restart <进程名>   重启指定进程"
    echo ""
    echo ""
    echo "容器中可用进程:"
    echo "  nginx               Nginx Web服务器"
    echo "  php-fpm             PHP-FPM进程管理器"
    echo "  default             默认队列工作进程"
    echo "  order_notify        订单通知进程"
    echo "  order_query         订单查询进程"
    echo "  usdt_transfer       USDT转账进程"
    echo ""
    echo "示例:"
    echo "  $0 -s                   显示所有进程状态"
    echo "  $0 -u                   显示所有进程的用户信息"
    echo "  $0 -a                   重启所有进程"
    echo "  $0 -r nginx             重启nginx进程"
    echo "  $0 -f default           强制重启default队列进程"
}

# 主函数
main() {
    # 检查是否以root权限运行
    if [ "$EUID" -ne 0 ] && [ "$(id -u)" -ne 0 ]; then
        log_warning "建议以root权限运行此脚本以确保所有功能正常"
    fi
    
    case "$1" in
        -h|--help)
            show_help
            ;;
        -s|--status)
            # 对于状态查看，只检查容器是否运行
            if ! check_container; then
                exit 1
            fi
            show_status
            ;;
        -u|--users)
            # 显示进程用户信息，只检查容器是否运行
            if ! check_container; then
                exit 1
            fi
            show_process_users
            ;;
        -a|--all)
            # 检查supervisor是否运行
            if ! check_supervisor; then
                exit 1
            fi
            restart_all
            ;;
        -q|--queue)
            # 检查supervisor是否运行
            if ! check_supervisor; then
                exit 1
            fi
            restart_queue_workers
            ;;
        -w|--web)
            # 检查supervisor是否运行
            if ! check_supervisor; then
                exit 1
            fi
            restart_web_services
            ;;
        -f|--force)
            if [ -z "$2" ]; then
                log_error "请指定要强制重启的进程名称"
                echo ""
                show_help
                exit 1
            fi
            # 检查supervisor是否运行
            if ! check_supervisor; then
                exit 1
            fi
            force_restart "$2"
            ;;
        -r|--restart)
            if [ -z "$2" ]; then
                log_error "请指定要重启的进程名称"
                echo ""
                show_help
                exit 1
            fi
            # 检查supervisor是否运行
            if ! check_supervisor; then
                exit 1
            fi
            restart_daemon "$2"
            ;;
        "")
            log_info "守护进程重启脚本已启动"
            # 对于默认行为，只检查容器是否运行
            if ! check_container; then
                exit 1
            fi
            show_status
            echo ""
            echo "使用 $0 --help 查看可用选项"
            ;;
        *)
            log_error "未知选项: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
