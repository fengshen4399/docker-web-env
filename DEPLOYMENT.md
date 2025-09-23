# Docker Web Environment 部署指南

## 🚀 快速部署

### 方法一：交互式安装（推荐）

```bash
# 1. 下载项目
git clone <your-repo-url>
cd docker-web-env

# 2. 运行交互式安装脚本
./install.sh

# 3. 按照菜单提示操作：
#    - 选择 1 安装 Docker（如果需要）
#    - 选择 2 部署环境
#    - 选择 3 启动服务
```

### 方法二：一键部署

```bash
# 1. 下载项目
git clone <your-repo-url>
cd docker-web-env

# 2. 运行一键部署脚本
./deploy.sh
```

## 📋 系统要求

### 支持的操作系统

- ✅ Ubuntu 18.04+
- ✅ Debian 9+
- ✅ CentOS 7+
- ✅ RHEL 7+
- ✅ Rocky Linux 8+
- ✅ AlmaLinux 8+
- ✅ Fedora 30+

### 硬件要求

- **CPU**: 1 核心以上
- **内存**: 512MB 以上
- **磁盘**: 1GB 以上可用空间
- **网络**: 需要访问互联网下载 Docker 镜像

## 🔧 详细安装步骤

### 1. 准备环境

```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# 或
sudo yum update -y  # CentOS/RHEL
```

### 2. 安装 Docker（如果未安装）

#### Ubuntu/Debian
```bash
# 安装依赖
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 添加 Docker 官方 GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### CentOS/RHEL
```bash
# 安装依赖
sudo yum install -y yum-utils

# 添加 Docker 仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 3. 启动 Docker 服务

```bash
# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker
```

### 4. 部署应用

```bash
# 下载项目
git clone <your-repo-url>
cd docker-web-env

# 运行交互式安装
./install.sh
```

## 🛠️ 管理命令

### 交互式管理

```bash
# 运行交互式脚本
./install.sh

# 菜单选项：
# 1) 安装 Docker
# 2) 部署环境
# 3) 启动服务
# 4) 停止服务
# 5) 重启服务
# 6) 查看状态
# 7) 查看日志
# 8) 进入容器
# 9) 使用 Composer
# 10) 打包部署
# 11) 管理工具
# 12) 退出
```

### 命令行管理

```bash
# 使用 web.sh 脚本
./scripts/web.sh start      # 启动服务
./scripts/web.sh stop       # 停止服务
./scripts/web.sh restart    # 重启服务
./scripts/web.sh status     # 查看状态
./scripts/web.sh logs       # 查看日志
./scripts/web.sh shell      # 进入容器
./scripts/web.sh composer   # 使用 Composer

# 使用 manage.sh 脚本
./scripts/manage.sh start
./scripts/manage.sh stop
./scripts/manage.sh restart
./scripts/manage.sh logs
```

### Docker Compose 命令

```bash
# 构建镜像
docker compose build

# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看状态
docker compose ps

# 查看日志
docker compose logs
docker compose logs -f  # 实时日志
```

## 📦 打包部署

### 创建部署包

```bash
# 创建完整包
./scripts/package.sh

# 创建最小化包
./scripts/package.sh minimal

# 创建配置文件包
./scripts/package.sh configs
```

### 部署到其他服务器

```bash
# 1. 上传部署包
scp docker-web-env-v1.4.0-minimal.tar.gz user@server:/home/

# 2. 在服务器上解压
tar -xzf docker-web-env-v1.4.0-minimal.tar.gz
cd docker-web-env

# 3. 运行交互式安装
./install.sh
```

## 🌐 访问应用

部署成功后，可以通过以下地址访问：

- **主页**: http://服务器IP:80/
- **健康检查**: http://服务器IP:80/health.php
- **PHP 信息**: http://服务器IP:80/index.php

## 🔍 故障排除

### 常见问题

#### 1. Docker 安装失败

```bash
# 检查系统版本
cat /etc/os-release

# 手动安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

#### 2. 端口冲突

```bash
# 检查端口占用
sudo netstat -tlnp | grep :80

# 停止占用端口的服务
sudo systemctl stop apache2  # Ubuntu/Debian
sudo systemctl stop httpd    # CentOS/RHEL
```

#### 3. 权限问题

```bash
# 检查目录权限
ls -la /home/app/default/

# 修复权限
sudo chown -R $USER:$USER /home/app/default/
sudo chmod -R 755 /home/app/default/
```

#### 4. 服务启动失败

```bash
# 查看详细日志
docker compose logs

# 检查配置文件
docker compose config

# 重新构建镜像
docker compose build --no-cache
```

### 日志查看

```bash
# 查看所有日志
docker compose logs

# 查看实时日志
docker compose logs -f

# 查看特定服务日志
docker compose logs web

# 查看错误日志
docker compose logs | grep -i error
```

### 性能监控

```bash
# 查看容器状态
docker compose ps

# 查看资源使用
docker stats

# 查看系统资源
htop
df -h
free -h
```

## 🔧 配置修改

### PHP 配置

```bash
# 编辑 PHP 配置
nano conf/php.ini

# 重启服务应用配置
docker compose restart
```

### Nginx 配置

```bash
# 编辑 Nginx 配置
nano conf/nginx.conf

# 重启服务应用配置
docker compose restart
```

### 添加 PHP 扩展

```bash
# 编辑 Dockerfile
nano build/Dockerfile

# 重新构建镜像
docker compose build --no-cache
docker compose up -d
```

## 📊 监控和维护

### 定期维护

```bash
# 清理 Docker 资源
docker system prune -f

# 更新镜像
docker compose pull
docker compose up -d

# 备份数据
tar -czf backup-$(date +%Y%m%d).tar.gz /home/app/default/
```

### 日志轮转

```bash
# 设置日志轮转
sudo nano /etc/logrotate.d/docker-web-env

# 内容：
/home/docker-web-env/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

## 🆘 获取帮助

### 查看帮助

```bash
# 查看脚本帮助
./install.sh
./scripts/web.sh
./scripts/manage.sh

# 查看 Docker 帮助
docker --help
docker compose --help
```

### 联系支持

- 📧 邮箱: support@example.com
- 🐛 问题反馈: GitHub Issues
- 📖 文档: README.md

## 📄 许可证

MIT License - 详见 LICENSE 文件