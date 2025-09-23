#!/bin/bash

# 远程管理脚本
# 用于管理已部署的远程服务器

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
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           🛠️  Docker Web Environment 远程管理               ║"
    echo "║                                                              ║"
    echo "║           管理已部署的远程服务器                              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}📋 使用方法:${NC}"
    echo ""
    echo -e "${GREEN}交互式管理${NC}"
    echo "  ./scripts/remote-manage.sh"
    echo ""
    echo -e "${GREEN}命令行管理${NC}"
    echo "  ./scripts/remote-manage.sh <IP> <用户名> <命令> [密钥路径] [密码]"
    echo ""
    echo -e "${BLUE}可用命令:${NC}"
    echo "  status      - 查看服务状态"
    echo "  start       - 启动服务"
    echo "  stop        - 停止服务"
    echo "  restart     - 重启服务"
    echo "  logs        - 查看日志"
    echo "  shell       - 进入容器"
    echo "  update      - 更新部署"
    echo "  health      - 健康检查"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  ./scripts/remote-manage.sh 192.168.1.100 root status"
    echo "  ./scripts/remote-manage.sh 192.168.1.100 ubuntu logs ~/.ssh/id_rsa"
    echo ""
}

# 远程执行命令
remote_execute() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local command=$5
    
    local ssh_cmd="ssh -o StrictHostKeyChecking=no"
    
    if [ -n "$key_path" ] && [ -f "$key_path" ]; then
        ssh_cmd="$ssh_cmd -i $key_path"
    fi
    
    if [ -n "$password" ] && command -v sshpass &> /dev/null; then
        sshpass -p "$password" $ssh_cmd "$username@$ip" "$command"
    else
        $ssh_cmd "$username@$ip" "$command"
    fi
}

# 远程管理命令
remote_manage() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local action=$5
    
    case $action in
        status)
            echo -e "${BLUE}📊 查看服务状态...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh status"
            ;;
        start)
            echo -e "${BLUE}▶️  启动服务...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh start"
            ;;
        stop)
            echo -e "${BLUE}⏹️  停止服务...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh stop"
            ;;
        restart)
            echo -e "${BLUE}🔄 重启服务...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh restart"
            ;;
        logs)
            echo -e "${BLUE}📋 查看日志...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh logs"
            ;;
        shell)
            echo -e "${BLUE}🐚 进入容器...${NC}"
            echo -e "${YELLOW}注意: 这将打开一个交互式 SSH 会话${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./scripts/web.sh shell"
            ;;
        update)
            echo -e "${BLUE}🔄 更新部署...${NC}"
            echo -e "${YELLOW}这将重新部署最新版本${NC}"
            # 这里可以调用远程部署脚本
            ;;
        health)
            echo -e "${BLUE}🏥 健康检查...${NC}"
            remote_execute "$ip" "$username" "$key_path" "$password" "curl -f http://localhost:80/health.php"
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $action${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 交互式管理
interactive_manage() {
    echo -e "${BLUE}📋 请输入远程服务器信息:${NC}"
    echo ""
    
    read -p "服务器 IP 地址: " ip
    if [ -z "$ip" ]; then
        echo -e "${RED}❌ IP 地址不能为空${NC}"
        exit 1
    fi
    
    read -p "SSH 用户名: " username
    if [ -z "$username" ]; then
        echo -e "${RED}❌ 用户名不能为空${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}认证方式选择:${NC}"
    echo "1) SSH 密钥认证"
    echo "2) 密码认证"
    read -p "请选择 (1-2): " auth_choice
    
    local key_path=""
    local password=""
    
    case $auth_choice in
        1)
            read -p "SSH 私钥路径 (默认: ~/.ssh/id_rsa): " key_path
            if [ -z "$key_path" ]; then
                key_path="$HOME/.ssh/id_rsa"
            fi
            if [ ! -f "$key_path" ]; then
                echo -e "${RED}❌ 密钥文件不存在: $key_path${NC}"
                exit 1
            fi
            ;;
        2)
            read -s -p "SSH 密码: " password
            echo ""
            if [ -z "$password" ]; then
                echo -e "${RED}❌ 密码不能为空${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            exit 1
            ;;
    esac
    
    # 管理菜单
    while true; do
        echo ""
        echo -e "${BLUE}🛠️  远程管理菜单 ($username@$ip):${NC}"
        echo "1) 📊 查看状态"
        echo "2) ▶️  启动服务"
        echo "3) ⏹️  停止服务"
        echo "4) 🔄 重启服务"
        echo "5) 📋 查看日志"
        echo "6) 🐚 进入容器"
        echo "7) 🏥 健康检查"
        echo "8) 🔄 更新部署"
        echo "9) ❌ 退出"
        echo ""
        read -p "请选择操作 (1-9): " choice
        
        case $choice in
            1)
                remote_manage "$ip" "$username" "$key_path" "$password" "status"
                ;;
            2)
                remote_manage "$ip" "$username" "$key_path" "$password" "start"
                ;;
            3)
                remote_manage "$ip" "$username" "$key_path" "$password" "stop"
                ;;
            4)
                remote_manage "$ip" "$username" "$key_path" "$password" "restart"
                ;;
            5)
                remote_manage "$ip" "$username" "$key_path" "$password" "logs"
                ;;
            6)
                remote_manage "$ip" "$username" "$key_path" "$password" "shell"
                ;;
            7)
                remote_manage "$ip" "$username" "$key_path" "$password" "health"
                ;;
            8)
                echo -e "${YELLOW}⚠️  更新部署功能需要重新运行部署脚本${NC}"
                echo -e "${BLUE}请使用: ./scripts/remote-deploy.sh $ip $username${NC}"
                ;;
            9)
                echo -e "${GREEN}👋 退出远程管理${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择${NC}"
                ;;
        esac
        
        echo -e "${BLUE}按 Enter 继续...${NC}"
        read
    done
}

# 主函数
main() {
    show_banner
    
    # 检查参数
    if [ $# -eq 0 ]; then
        # 交互式模式
        interactive_manage
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    elif [ $# -ge 3 ]; then
        # 命令行参数模式
        local ip=$1
        local username=$2
        local action=$3
        local key_path=${4:-""}
        local password=${5:-""}
        
        remote_manage "$ip" "$username" "$key_path" "$password" "$action"
    else
        echo -e "${RED}❌ 参数不足${NC}"
        show_help
        exit 1
    fi
}

# 运行主函数
main "$@"
