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
    if ! sudo docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "错误: 容器 ${CONTAINER_NAME} 未运行"
        echo "请先启动容器: docker-compose up -d"
        return 1
    fi
    return 0
}

# 检查容器内supervisor是否运行
check_supervisor() {
    if ! check_container; then
        return 1
    fi
    
    if ! supervisorctl_exec status > /dev/null 2>&1; then
        log_error "容器内 Supervisor 未运行，请先启动 supervisord"
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
    supervisorctl_exec status
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
    
    # 检查supervisor是否运行
    if ! check_supervisor; then
        exit 1
    fi
    
    case "$1" in
        -h|--help)
            show_help
            ;;
        -s|--status)
            show_status
            ;;
        -a|--all)
            restart_all
            ;;
        -q|--queue)
            restart_queue_workers
            ;;
        -w|--web)
            restart_web_services
            ;;
        -f|--force)
            if [ -z "$2" ]; then
                log_error "请指定要强制重启的进程名称"
                echo ""
                show_help
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
            restart_daemon "$2"
            ;;
        "")
            log_info "守护进程重启脚本已启动"
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
