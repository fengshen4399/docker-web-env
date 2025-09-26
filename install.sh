#!/bin/bash

# Docker Web Environment 交互式安装脚本
# 提供菜单选择，支持一键安装和管理

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
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║           🐳 Docker Web Environment v1.4.0                  ║"
    echo "║                                                              ║"
    echo "║           PHP 8.3 + Nginx + Supervisor + Composer           ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 显示主菜单
show_menu() {
    echo -e "${BLUE}📋 请选择操作：${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} 🐳 安装 Docker"
    echo -e "${GREEN}2)${NC} 🚀 部署环境"
    echo -e "${GREEN}3)${NC} ▶️  启动服务"
    echo -e "${GREEN}4)${NC} ⏹️  停止服务"
    echo -e "${GREEN}5)${NC} 🔄 重启服务"
    echo -e "${GREEN}6)${NC} 📊 查看状态"
    echo -e "${GREEN}7)${NC} 📋 查看日志"
    echo -e "${GREEN}8)${NC} 🐚 进入容器"
    echo -e "${GREEN}9)${NC} 📦 使用 Composer"
    echo -e "${GREEN}10)${NC} 📦 打包部署"
    echo -e "${GREEN}11)${NC} 🚀 远程部署"
    echo -e "${GREEN}12)${NC} 🛠️  远程管理"
    echo -e "${GREEN}13)${NC} 🛠️  管理工具"
    echo -e "${GREEN}14)${NC} ❌ 退出"
    echo ""
}

# 检查 Docker 是否安装
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker 已安装，版本: $(docker --version)${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker 未安装${NC}"
        return 1
    fi
}

# 检查 Docker Compose
check_docker_compose() {
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose 已就绪${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker Compose 未正确安装${NC}"
        return 1
    fi
}

# 安装 Docker
install_docker() {
    echo -e "${BLUE}🐳 开始安装 Docker...${NC}"
    
    # 检查是否为 root 用户
    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  检测到 root 用户，建议使用普通用户运行此脚本${NC}"
        echo -e "${YELLOW}   如需继续，请按 Enter，否则按 Ctrl+C 退出${NC}"
        read
    fi
    
    # 检查 sudo 权限
    if ! sudo -n true 2>/dev/null; then
        echo -e "${BLUE}🔐 需要 sudo 权限来安装 Docker，请输入密码：${NC}"
        sudo -v
    fi
    
    # 检测操作系统并安装 Docker
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo -e "${RED}❌ 无法检测操作系统${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 检测到操作系统: $OS $VER${NC}"
    
    case "$OS" in
        *"Ubuntu"*)
            echo -e "${BLUE}🔧 安装 Docker (Ubuntu)...${NC}"
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"Debian"*)
            echo -e "${BLUE}🔧 安装 Docker (Debian)...${NC}"
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"CentOS"*|*"Red Hat"*|*"Rocky"*|*"AlmaLinux"*)
            echo -e "${BLUE}🔧 安装 Docker (CentOS/RHEL)...${NC}"
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *"Fedora"*)
            echo -e "${BLUE}🔧 安装 Docker (Fedora)...${NC}"
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            echo -e "${RED}❌ 不支持的操作系统: $OS${NC}"
            echo -e "${YELLOW}请手动安装 Docker: https://docs.docker.com/engine/install/${NC}"
            return 1
            ;;
    esac
    
    # 启动 Docker 服务
    echo -e "${BLUE}🚀 启动 Docker 服务...${NC}"
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到 docker 组
    echo -e "${BLUE}👤 添加用户到 docker 组...${NC}"
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker 安装完成！${NC}"
    echo -e "${YELLOW}⚠️  请重新登录或运行 'newgrp docker' 后再次执行此脚本${NC}"
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 部署环境
deploy_environment() {
    echo -e "${BLUE}🚀 开始部署环境...${NC}"
    
    # 创建必要的目录
    echo -e "${BLUE}📁 创建必要的目录...${NC}"
    mkdir -p /home/app/default
    mkdir -p ./log
    
    # 设置目录权限
    echo -e "${BLUE}🔐 设置目录权限...${NC}"
    chmod 777 /home/app/default
    chmod 755 ./log
    
    # 创建默认的测试文件（如果不存在）
    echo -e "${BLUE}📝 检查并创建测试文件...${NC}"
    
    if [ ! -f /home/app/default/index.php ]; then
        echo -e "${GREEN}✓ 创建 index.php${NC}"
        cat > /home/app/default/index.php << 'EOF'
<?php
echo "<h1>Hello from PHP!</h1>";
echo "<p>This is a custom Docker environment with PHP 8.3 and Nginx.</p>";
echo "<h2>PHP Information:</h2>";
phpinfo();
?>
EOF
    else
        echo -e "${YELLOW}⚠ index.php 已存在，跳过创建${NC}"
    fi

    if [ ! -f /home/app/default/health.php ]; then
        echo -e "${GREEN}✓ 创建 health.php${NC}"
        cat > /home/app/default/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'timestamp' => date('Y-m-d H:i:s'),
    'php_version' => PHP_VERSION
]);
?>
EOF
    else
        echo -e "${YELLOW}⚠ health.php 已存在，跳过创建${NC}"
    fi
    
    # 设置系统时区为中国
    echo -e "${BLUE}🕐 设置系统时区为中国...${NC}"
    if command -v timedatectl &> /dev/null; then
        sudo timedatectl set-timezone Asia/Shanghai
        echo -e "${GREEN}✓ 系统时区已设置为 Asia/Shanghai${NC}"
    else
        # 备用方法
        sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        echo "Asia/Shanghai" | sudo tee /etc/timezone > /dev/null
        echo -e "${GREEN}✓ 系统时区已设置为 Asia/Shanghai (备用方法)${NC}"
    fi
    
    # 显示当前时间
    echo -e "${BLUE}📅 当前时间: $(date)${NC}"
    
    # 构建并启动服务
    echo -e "${BLUE}🔨 构建 Docker 镜像...${NC}"
    docker compose build
    
    echo -e "${BLUE}🚀 启动服务...${NC}"
    docker compose up -d
    
    # 等待服务启动
    echo -e "${BLUE}⏳ 等待服务启动...${NC}"
    sleep 15
    
    # 检查服务状态
    echo -e "${BLUE}🔍 检查服务状态...${NC}"
    if docker compose ps | grep -q "Up.*healthy\|Up.*unhealthy"; then
        echo -e "${GREEN}✅ 服务启动成功！${NC}"
        echo ""
        echo -e "${GREEN}🌐 访问地址:${NC}"
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "${GREEN}   - 主页: http://$SERVER_IP:80/${NC}"
        echo -e "${GREEN}   - 健康检查: http://$SERVER_IP:80/health.php${NC}"
        echo -e "${GREEN}   - PHP 信息: http://$SERVER_IP:80/index.php${NC}"
    else
        echo -e "${RED}❌ 服务启动失败，请检查日志:${NC}"
        docker compose logs
        return 1
    fi
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 启动服务
start_service() {
    echo -e "${BLUE}▶️  启动服务...${NC}"
    docker compose up -d
    echo -e "${GREEN}✅ 服务已启动${NC}"
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 停止服务
stop_service() {
    echo -e "${BLUE}⏹️  停止服务...${NC}"
    docker compose down
    echo -e "${GREEN}✅ 服务已停止${NC}"
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 重启服务
restart_service() {
    echo -e "${BLUE}🔄 重启服务...${NC}"
    docker compose restart
    echo -e "${GREEN}✅ 服务已重启${NC}"
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 查看状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    docker compose ps
    echo ""
    echo -e "${BLUE}📈 资源使用:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📋 服务日志:${NC}"
    echo -e "${YELLOW}选择日志类型:${NC}"
    echo "1) 所有日志"
    echo "2) 实时日志"
    echo "3) 仅错误日志"
    echo "4) 返回主菜单"
    read -p "请选择 (1-4): " log_choice
    
    case $log_choice in
        1)
            docker compose logs
            ;;
        2)
            echo -e "${YELLOW}按 Ctrl+C 退出实时日志${NC}"
            docker compose logs -f
            ;;
        3)
            docker compose logs | grep -i error
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 进入容器
enter_container() {
    echo -e "${BLUE}🐚 进入容器...${NC}"
    echo -e "${YELLOW}使用 'exit' 命令退出容器${NC}"
    docker exec -it my_web bash
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 使用 Composer
use_composer() {
    echo -e "${BLUE}📦 Composer 操作:${NC}"
    echo "1) 安装依赖"
    echo "2) 更新依赖"
    echo "3) 安装新包"
    echo "4) 查看已安装包"
    echo "5) 返回主菜单"
    read -p "请选择 (1-5): " composer_choice
    
    case $composer_choice in
        1)
            echo -e "${BLUE}安装依赖...${NC}"
            docker exec my_web composer install
            ;;
        2)
            echo -e "${BLUE}更新依赖...${NC}"
            docker exec my_web composer update
            ;;
        3)
            read -p "请输入要安装的包名: " package_name
            echo -e "${BLUE}安装包: $package_name${NC}"
            docker exec my_web composer require "$package_name"
            ;;
        4)
            echo -e "${BLUE}已安装的包:${NC}"
            docker exec my_web composer show
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 打包部署
package_deployment() {
    echo -e "${BLUE}📦 打包部署:${NC}"
    echo "1) 创建完整包"
    echo "2) 创建最小化包"
    echo "3) 创建配置文件包"
    echo "4) 返回主菜单"
    read -p "请选择 (1-4): " package_choice
    
    case $package_choice in
        1)
            ./scripts/package.sh
            ;;
        2)
            ./scripts/package.sh minimal
            ;;
        3)
            ./scripts/package.sh configs
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 定时任务管理
cron_management_menu() {
    echo -e "${BLUE}⏰ 定时任务管理 (基于配置文件)${NC}"
    echo "========================================="
    echo "1) 查看当前任务"
    echo "2) 编辑配置文件"
    echo "3) 重载任务配置"
    echo "4) 查看任务日志"
    echo "5) 添加常用任务"
    echo "6) 清空所有任务"
    echo "7) 查看服务状态"
    echo "8) 返回主菜单"
    read -p "请选择 (1-8): " cron_choice
    
    case $cron_choice in
        1)
            echo -e "${BLUE}📋 当前定时任务:${NC}"
            sudo docker exec my_web cron-manager status
            ;;
        2)
            edit_cron_config
            ;;
        3)
            echo -e "${BLUE}🔄 重载定时任务配置...${NC}"
            sudo docker exec my_web cron-manager reload
            echo -e "${GREEN}✓ 配置重载完成${NC}"
            ;;
        4)
            view_cron_logs
            ;;
        5)
            add_common_tasks
            ;;
        6)
            echo -e "${YELLOW}⚠️ 确定要清空所有定时任务吗？${NC}"
            read -p "输入 'yes' 确认: " confirm
            if [ "$confirm" = "yes" ]; then
                sudo docker exec my_web crontab -r
                echo -e "${GREEN}✓ 所有定时任务已清空${NC}"
            fi
            ;;
        7)
            echo -e "${BLUE}📊 Cron服务状态:${NC}"
            sudo docker exec my_web supervisorctl status cron
            echo -e "${BLUE}📊 当前系统时间:${NC}"
            sudo docker exec my_web date
            ;;
        8)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 编辑定时任务配置文件
edit_cron_config() {
    echo -e "${BLUE}📝 编辑定时任务配置文件${NC}"
    echo -e "${YELLOW}配置文件路径: /etc/crontasks/crontab.conf${NC}"
    echo ""
    echo "当前配置内容:"
    sudo docker exec my_web cat /etc/crontasks/crontab.conf
    echo ""
    echo -e "${BLUE}选择操作:${NC}"
    echo "1) 查看配置示例"
    echo "2) 添加新任务到配置文件"
    echo "3) 返回"
    read -p "请选择: " edit_choice
    
    case $edit_choice in
        1)
            show_cron_examples
            ;;
        2)
            add_task_to_config
            ;;
        3)
            return
            ;;
    esac
}

# 显示定时任务配置示例
show_cron_examples() {
    echo -e "${BLUE}📖 定时任务配置示例:${NC}"
    echo ""
    echo "# 每5分钟执行一次"
    echo "*/5 * * * * echo \"每5分钟执行\" >> /var/log/crontasks/test.log 2>&1"
    echo ""
    echo "# 每天凌晨2点执行"
    echo "0 2 * * * cd /www && php backup.php >> /var/log/crontasks/backup.log 2>&1"
    echo ""
    echo "# 每周日凌晨3点清理日志"
    echo "0 3 * * 0 find /var/log/crontasks -name \"*.log\" -mtime +7 -delete"
    echo ""
    echo "# 每小时检查系统状态"
    echo "0 * * * * df -h > /var/log/crontasks/diskusage.log 2>&1"
    echo ""
    echo -e "${YELLOW}格式说明: 分(0-59) 时(0-23) 日(1-31) 月(1-12) 周(0-7)${NC}"
}

# 添加任务到配置文件
add_task_to_config() {
    echo -e "${BLUE}➕ 添加新任务到配置文件${NC}"
    echo "选择任务类型:"
    echo "1) PHP脚本执行"
    echo "2) 系统命令"
    echo "3) 日志清理"
    echo "4) 数据备份"
    echo "5) 自定义任务"
    read -p "请选择: " task_type
    
    case $task_type in
        1)
            read -p "PHP脚本路径 (相对于/www): " php_script
            read -p "执行时间 (cron格式): " cron_time
            task_line="$cron_time cd /www && php $php_script >> /var/log/crontasks/php_${php_script//\//_}.log 2>&1"
            ;;
        2)
            read -p "系统命令: " sys_cmd
            read -p "执行时间 (cron格式): " cron_time
            read -p "日志文件名: " log_name
            task_line="$cron_time $sys_cmd >> /var/log/crontasks/$log_name.log 2>&1"
            ;;
        3)
            read -p "执行时间 (cron格式, 建议: 0 3 * * 0): " cron_time
            read -p "保留天数 (默认7天): " keep_days
            keep_days=${keep_days:-7}
            task_line="$cron_time find /var/log/crontasks -name \"*.log\" -mtime +$keep_days -delete"
            ;;
        4)
            read -p "备份路径 (相对于/www): " backup_path
            read -p "执行时间 (cron格式): " cron_time
            task_line="$cron_time cd /www && tar -czf /var/log/crontasks/backup_\$(date +%Y%m%d_%H%M%S).tar.gz $backup_path >> /var/log/crontasks/backup.log 2>&1"
            ;;
        5)
            read -p "自定义命令: " custom_cmd
            read -p "执行时间 (cron格式): " cron_time
            read -p "日志文件名: " log_name
            task_line="$cron_time $custom_cmd >> /var/log/crontasks/$log_name.log 2>&1"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return
            ;;
    esac
    
    # 添加任务注释和内容到配置文件
    echo -e "${BLUE}添加任务到配置文件...${NC}"
    sudo docker exec my_web bash -c "echo '# 添加于 $(date)' >> /etc/crontasks/crontab.conf"
    sudo docker exec my_web bash -c "echo '$task_line' >> /etc/crontasks/crontab.conf"
    sudo docker exec my_web bash -c "echo '' >> /etc/crontasks/crontab.conf"
    
    echo -e "${GREEN}✓ 任务已添加到配置文件${NC}"
    echo -e "${YELLOW}⚠️ 请运行 '重载任务配置' 使配置生效${NC}"
}

# 查看定时任务日志
view_cron_logs() {
    echo -e "${BLUE}📋 定时任务日志${NC}"
    
    # 列出日志文件
    echo -e "${YELLOW}可用日志文件:${NC}"
    sudo docker exec my_web ls -la /var/log/crontasks/ 2>/dev/null || echo "暂无日志文件"
    
    echo ""
    read -p "请输入日志文件名 (不含路径，回车查看所有): " log_file
    
    if [ -z "$log_file" ]; then
        echo -e "${BLUE}📄 所有日志文件概览:${NC}"
        sudo docker exec my_web find /var/log/crontasks -name "*.log" -exec basename {} \; | while read file; do
            echo -e "${CYAN}=== $file (最后10行) ===${NC}"
            sudo docker exec my_web tail -10 "/var/log/crontasks/$file" 2>/dev/null || echo "无法读取"
            echo ""
        done
    else
        echo -e "${BLUE}📄 $log_file 内容 (最后50行):${NC}"
        sudo docker exec my_web tail -50 "/var/log/crontasks/$log_file" 2>/dev/null || echo "日志文件不存在"
    fi
}

# 添加常用任务
add_common_tasks() {
    echo -e "${BLUE}🚀 添加常用定时任务${NC}"
    echo "选择要添加的常用任务:"
    echo "1) 每5分钟系统健康检查"
    echo "2) 每天凌晨2点日志清理"
    echo "3) 每小时磁盘使用监控"
    echo "4) 每天凌晨3点数据备份"
    echo "5) 返回"
    read -p "请选择: " common_choice
    
    case $common_choice in
        1)
            task="*/5 * * * * echo \"\$(date): System OK\" >> /var/log/crontasks/health.log 2>&1"
            ;;
        2)
            task="0 2 * * * find /var/log/crontasks -name \"*.log\" -mtime +7 -delete"
            ;;
        3)
            task="0 * * * * df -h > /var/log/crontasks/diskusage.log 2>&1"
            ;;
        4)
            task="0 3 * * * cd /www && tar -czf /var/log/crontasks/backup_\$(date +%Y%m%d).tar.gz . >> /var/log/crontasks/backup.log 2>&1"
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return
            ;;
    esac
    
    # 添加到配置文件
    sudo docker exec my_web bash -c "echo '# 常用任务 - 添加于 $(date)' >> /etc/crontasks/crontab.conf"
    sudo docker exec my_web bash -c "echo '$task' >> /etc/crontasks/crontab.conf"
    sudo docker exec my_web bash -c "echo '' >> /etc/crontasks/crontab.conf"
    
    echo -e "${GREEN}✓ 常用任务已添加到配置文件${NC}"
    echo -e "${YELLOW}⚠️ 请运行 '重载任务配置' 使配置生效${NC}"
}

# 管理工具
manage_tools() {
    echo -e "${BLUE}🛠️  管理工具:${NC}"
    echo "1) 安装快捷别名"
    echo "2) 清理 Docker 资源"
    echo "3) 查看系统信息"
    echo "4) 定时任务管理"
    echo "5) 返回主菜单"
    read -p "请选择 (1-5): " tool_choice
    
    case $tool_choice in
        1)
            echo -e "${BLUE}安装快捷别名...${NC}"
            ./scripts/install-commands.sh
            ;;
        2)
            echo -e "${BLUE}清理 Docker 资源...${NC}"
            docker system prune -f
            echo -e "${GREEN}✅ 清理完成${NC}"
            ;;
        3)
            echo -e "${BLUE}系统信息:${NC}"
            echo "操作系统: $(uname -a)"
            echo "Docker 版本: $(docker --version)"
            echo "Docker Compose 版本: $(docker compose version)"
            echo "磁盘使用: $(df -h /)"
            echo "内存使用: $(free -h)"
            ;;
        4)
            cron_management_menu
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo -e "${BLUE}按 Enter 继续...${NC}"
    read
}

# 主循环
main() {
    while true; do
        show_banner
        show_menu
        
        read -p "请选择操作 (1-14): " choice
        
        case $choice in
            1)
                install_docker
                ;;
            2)
                if ! check_docker; then
                    echo -e "${RED}请先安装 Docker${NC}"
                    echo -e "${BLUE}按 Enter 继续...${NC}"
                    read
                    continue
                fi
                if ! check_docker_compose; then
                    echo -e "${RED}Docker Compose 未正确安装${NC}"
                    echo -e "${BLUE}按 Enter 继续...${NC}"
                    read
                    continue
                fi
                deploy_environment
                ;;
            3)
                start_service
                ;;
            4)
                stop_service
                ;;
            5)
                restart_service
                ;;
            6)
                show_status
                ;;
            7)
                show_logs
                ;;
            8)
                enter_container
                ;;
            9)
                use_composer
                ;;
            10)
                package_deployment
                ;;
            11)
                echo -e "${BLUE}🚀 启动远程部署...${NC}"
                ./scripts/remote-deploy.sh
                echo -e "${BLUE}按 Enter 继续...${NC}"
                read
                ;;
            12)
                echo -e "${BLUE}🛠️  启动远程管理...${NC}"
                ./scripts/remote-manage.sh
                echo -e "${BLUE}按 Enter 继续...${NC}"
                read
                ;;
            13)
                manage_tools
                ;;
            14)
                echo -e "${GREEN}👋 再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                echo -e "${BLUE}按 Enter 继续...${NC}"
                read
                ;;
        esac
    done
}

# 运行主程序
main
