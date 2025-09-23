#!/bin/bash

# 远程部署脚本
# 支持通过 SSH 密钥或密码连接到远程服务器进行部署

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
    echo "║           🚀 Docker Web Environment 远程部署                ║"
    echo "║                                                              ║"
    echo "║           支持 SSH 密钥和密码认证                            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}📋 使用方法:${NC}"
    echo ""
    echo -e "${GREEN}方法一：交互式部署${NC}"
    echo "  ./scripts/remote-deploy.sh"
    echo ""
    echo -e "${GREEN}方法二：命令行参数${NC}"
    echo "  ./scripts/remote-deploy.sh <IP> <用户名> [密钥路径] [密码]"
    echo ""
    echo -e "${GREEN}方法三：配置文件${NC}"
    echo "  ./scripts/remote-deploy.sh --config config.conf"
    echo ""
    echo -e "${BLUE}参数说明:${NC}"
    echo "  IP地址      - 远程服务器 IP 地址"
    echo "  用户名      - SSH 登录用户名"
    echo "  密钥路径    - SSH 私钥文件路径（可选）"
    echo "  密码        - SSH 登录密码（可选，与密钥二选一）"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  ./scripts/remote-deploy.sh 192.168.1.100 root ~/.ssh/id_rsa"
    echo "  ./scripts/remote-deploy.sh 192.168.1.100 ubuntu '' mypassword"
    echo ""
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    if ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi
    
    if ! command -v scp &> /dev/null; then
        missing_deps+=("scp")
    fi
    
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}⚠️  sshpass 未安装，将使用交互式密码输入${NC}"
        echo -e "${BLUE}   如需自动密码输入，请安装: sudo apt-get install sshpass${NC}"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ 缺少必要依赖: ${missing_deps[*]}${NC}"
        echo -e "${BLUE}请安装缺少的依赖后重试${NC}"
        exit 1
    fi
}

# 测试 SSH 连接
test_ssh_connection() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    
    echo -e "${BLUE}🔍 测试 SSH 连接...${NC}"
    
    local ssh_cmd="ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no"
    
    if [ -n "$key_path" ] && [ -f "$key_path" ]; then
        ssh_cmd="$ssh_cmd -i $key_path"
    fi
    
    if [ -n "$password" ] && command -v sshpass &> /dev/null; then
        if sshpass -p "$password" $ssh_cmd "$username@$ip" "echo 'SSH连接成功'" 2>/dev/null; then
            echo -e "${GREEN}✅ SSH 连接成功${NC}"
            return 0
        else
            echo -e "${RED}❌ SSH 连接失败${NC}"
            return 1
        fi
    else
        if [ -n "$key_path" ] && [ -f "$key_path" ]; then
            echo -e "${BLUE}🔑 使用密钥认证测试连接...${NC}"
        else
            echo -e "${YELLOW}⚠️  请手动输入密码进行连接测试${NC}"
        fi
        if $ssh_cmd "$username@$ip" "echo 'SSH连接成功'" 2>/dev/null; then
            echo -e "${GREEN}✅ SSH 连接成功${NC}"
            return 0
        else
            echo -e "${RED}❌ SSH 连接失败${NC}"
            return 1
        fi
    fi
}

# 上传部署包
upload_package() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local package_path=$5
    
    echo -e "${BLUE}📦 上传部署包到远程服务器...${NC}"
    
    local scp_cmd="scp -o StrictHostKeyChecking=no"
    
    if [ -n "$key_path" ] && [ -f "$key_path" ]; then
        scp_cmd="$scp_cmd -i $key_path"
    fi
    
    if [ -n "$password" ] && command -v sshpass &> /dev/null; then
        if sshpass -p "$password" $scp_cmd "$package_path" "$username@$ip:/tmp/" 2>/dev/null; then
            echo -e "${GREEN}✅ 部署包上传成功${NC}"
            return 0
        else
            echo -e "${RED}❌ 部署包上传失败${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  请手动输入密码进行文件上传${NC}"
        if $scp_cmd "$package_path" "$username@$ip:/tmp/" 2>/dev/null; then
            echo -e "${GREEN}✅ 部署包上传成功${NC}"
            return 0
        else
            echo -e "${RED}❌ 部署包上传失败${NC}"
            return 1
        fi
    fi
}

# 远程执行命令
remote_execute() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local command=$5
    local use_sudo=${6:-false}
    
    local ssh_cmd="ssh -o StrictHostKeyChecking=no"
    
    if [ -n "$key_path" ] && [ -f "$key_path" ]; then
        ssh_cmd="$ssh_cmd -i $key_path"
    fi
    
    # 如果需要 sudo，添加 sudo 前缀
    if [ "$use_sudo" = "true" ]; then
        command="sudo $command"
    fi
    
    if [ -n "$password" ] && command -v sshpass &> /dev/null; then
        sshpass -p "$password" $ssh_cmd "$username@$ip" "$command"
    else
        # 对于密钥认证，使用交互式模式
        $ssh_cmd -t "$username@$ip" "$command"
    fi
}

# 远程部署
remote_deploy() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local package_name=$5
    
    echo -e "${BLUE}🚀 开始远程部署...${NC}"
    
    # 1. 解压部署包
    echo -e "${BLUE}📦 解压部署包...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "cd /tmp && tar -xzf $package_name"
    
    # 2. 移动到目标目录（可能需要 sudo）
    echo -e "${BLUE}📁 移动到目标目录...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "cd /tmp && sudo mv docker-web-env /home/ && cd /home/docker-web-env" true
    
    # 3. 设置执行权限（可能需要 sudo）
    echo -e "${BLUE}🔐 设置执行权限...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && sudo chmod +x *.sh scripts/*.sh" true
    
    # 4. 运行部署脚本
    echo -e "${BLUE}🚀 运行部署脚本...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && ./deploy.sh"
    
    # 5. 检查部署状态
    echo -e "${BLUE}🔍 检查部署状态...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "cd /home/docker-web-env && docker compose ps"
    
    # 6. 清理临时文件
    echo -e "${BLUE}🧹 清理临时文件...${NC}"
    remote_execute "$ip" "$username" "$key_path" "$password" "rm -f /tmp/$package_name"
    
    echo -e "${GREEN}✅ 远程部署完成！${NC}"
}

# 交互式输入
interactive_input() {
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
    
    # 选择部署包
    echo ""
    echo -e "${BLUE}选择部署包:${NC}"
    echo "1) 完整包 (推荐)"
    echo "2) 最小化包"
    echo "3) 配置文件包"
    read -p "请选择 (1-3): " package_choice
    
    local package_name=""
    case $package_choice in
        1)
            package_name="docker-web-env-v1.4.0-full.tar.gz"
            ;;
        2)
            package_name="docker-web-env-v1.4.0-minimal.tar.gz"
            ;;
        3)
            package_name="docker-web-env-v1.4.0-configs.tar.gz"
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            exit 1
            ;;
    esac
    
    # 检查部署包是否存在
    if [ ! -f "/home/releases/$package_name" ]; then
        echo -e "${RED}❌ 部署包不存在: /home/releases/$package_name${NC}"
        echo -e "${BLUE}请先运行 ./scripts/package.sh 创建部署包${NC}"
        exit 1
    fi
    
    # 确认部署
    echo ""
    echo -e "${YELLOW}📋 部署信息确认:${NC}"
    echo "  服务器: $username@$ip"
    echo "  认证方式: $([ -n "$key_path" ] && echo "SSH 密钥 ($key_path)" || echo "密码认证")"
    echo "  部署包: $package_name"
    echo ""
    read -p "确认开始部署? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ 部署已取消${NC}"
        exit 0
    fi
    
    # 执行部署
    deploy_to_remote "$ip" "$username" "$key_path" "$password" "/home/releases/$package_name" "$package_name"
}

# 从配置文件部署
deploy_from_config() {
    local config_file=$1
    
    echo -e "${BLUE}📋 读取配置文件: $config_file${NC}"
    
    # 读取配置文件
    source "$config_file"
    
    # 验证必要参数
    if [ -z "$SERVER_IP" ] || [ -z "$SERVER_USER" ]; then
        echo -e "${RED}❌ 配置文件缺少必要参数: SERVER_IP 或 SERVER_USER${NC}"
        exit 1
    fi
    
    # 设置认证参数
    local key_path=""
    local password=""
    
    if [ "$AUTH_TYPE" = "key" ]; then
        if [ -z "$SSH_KEY_PATH" ]; then
            echo -e "${RED}❌ 配置文件缺少 SSH_KEY_PATH${NC}"
            exit 1
        fi
        # 展开波浪号路径
        key_path="${SSH_KEY_PATH/#\~/$HOME}"
    elif [ "$AUTH_TYPE" = "password" ]; then
        if [ -z "$SSH_PASSWORD" ]; then
            echo -e "${RED}❌ 配置文件缺少 SSH_PASSWORD${NC}"
            exit 1
        fi
        password="$SSH_PASSWORD"
    else
        echo -e "${RED}❌ 无效的认证类型: $AUTH_TYPE${NC}"
        exit 1
    fi
    
    # 设置部署包
    local package_name=""
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
    
    local package_path="/home/releases/$package_name"
    
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
    
    # 确认部署
    read -p "确认开始部署? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ 部署已取消${NC}"
        exit 0
    fi
    
    # 执行部署
    deploy_to_remote "$SERVER_IP" "$SERVER_USER" "$key_path" "$password" "$package_path" "$package_name"
}

# 执行远程部署
deploy_to_remote() {
    local ip=$1
    local username=$2
    local key_path=$3
    local password=$4
    local package_path=$5
    local package_name=$6
    
    echo -e "${BLUE}🚀 开始远程部署到 $username@$ip${NC}"
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 测试连接
    if ! test_ssh_connection "$ip" "$username" "$key_path" "$password"; then
        echo -e "${RED}❌ 无法连接到远程服务器${NC}"
        exit 1
    fi
    
    # 上传部署包
    if ! upload_package "$ip" "$username" "$key_path" "$password" "$package_path"; then
        echo -e "${RED}❌ 部署包上传失败${NC}"
        exit 1
    fi
    
    # 执行远程部署
    remote_deploy "$ip" "$username" "$key_path" "$password" "$package_name"
    
    echo ""
    echo -e "${GREEN}🎉 远程部署完成！${NC}"
    echo -e "${BLUE}🌐 访问地址: http://$ip:80/${NC}"
    echo -e "${BLUE}📋 管理命令: ssh $username@$ip 'cd /home/docker-web-env && ./scripts/web.sh status'${NC}"
}

# 主函数
main() {
    show_banner
    
    # 检查参数
    if [ $# -eq 0 ]; then
        # 交互式模式
        interactive_input
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    elif [ "$1" = "--config" ]; then
        # 配置文件模式
        local config_file=${2:-"remote-deploy.conf"}
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ 配置文件不存在: $config_file${NC}"
            exit 1
        fi
        deploy_from_config "$config_file"
    elif [ $# -ge 2 ]; then
        # 命令行参数模式
        local ip=$1
        local username=$2
        local key_path=${3:-""}
        local password=${4:-""}
        
        # 选择部署包
        local package_name="docker-web-env-v1.4.0-minimal.tar.gz"
        local package_path="/home/releases/$package_name"
        
        if [ ! -f "$package_path" ]; then
            echo -e "${RED}❌ 部署包不存在: $package_path${NC}"
            echo -e "${BLUE}请先运行 ./scripts/package.sh 创建部署包${NC}"
            exit 1
        fi
        
        deploy_to_remote "$ip" "$username" "$key_path" "$password" "$package_path" "$package_name"
    else
        echo -e "${RED}❌ 参数不足${NC}"
        show_help
        exit 1
    fi
}

# 运行主函数
main "$@"
