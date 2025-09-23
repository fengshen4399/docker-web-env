# Docker Web Environment v1.4.0

一个基于 PHP 8.3 + Nginx + Supervisor 的 Docker Web 开发环境，内置 Composer 和常用 PHP 扩展。

## 🚀 快速开始

### 方法一：交互式安装（推荐）

```bash
# 克隆或下载项目
git clone <your-repo-url>
cd docker-web-env

# 运行交互式安装脚本
./install.sh
```

### 方法二：一键部署

```bash
# 克隆或下载项目
git clone <your-repo-url>
cd docker-web-env

# 一键部署（自动安装 Docker + 部署）
./deploy.sh
```

### 方法三：手动部署

```bash
# 1. 确保 Docker 已安装
docker --version
docker compose version

# 2. 创建必要目录
mkdir -p /home/app/default
mkdir -p ./log

# 3. 构建并启动
docker compose build
docker compose up -d

# 4. 检查状态
docker compose ps
```

## 📁 项目结构

```
docker-web-env/
├── build/                    # Docker 构建文件
│   └── Dockerfile           # 自定义 PHP 8.3 + Nginx 镜像
├── conf/                    # 配置文件
│   ├── nginx.conf          # Nginx 配置
│   ├── php.ini             # PHP 配置
│   └── php-fpm.conf        # PHP-FPM 配置
├── supervisor/              # Supervisor 配置
│   ├── supervisord.conf    # 主配置
│   └── supervisor.d/       # 进程配置
│       └── php-fpm.conf    # PHP-FPM 进程配置
├── scripts/                 # 管理脚本
│   ├── web.sh              # 主要管理脚本
│   ├── manage.sh           # 简化管理脚本
│   ├── aliases.sh          # 快捷别名
│   ├── install-commands.sh # 安装全局命令
│   └── package.sh          # 打包脚本
├── log/                     # 日志目录
├── docker-compose.yml       # Docker Compose 配置
├── deploy.sh               # 一键部署脚本
├── install.sh              # 交互式安装脚本
└── README.md               # 项目说明
```

## 🛠️ 管理命令

### 使用 install.sh（交互式）

```bash
# 运行交互式安装脚本
./install.sh

# 选择菜单选项：
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
# 11) 远程部署
# 12) 远程管理
# 13) 管理工具
# 14) 退出
```

### 使用 web.sh（命令行）

```bash
# 查看所有可用命令
./scripts/web.sh

# 常用命令
./scripts/web.sh start      # 启动服务
./scripts/web.sh stop       # 停止服务
./scripts/web.sh restart    # 重启服务
./scripts/web.sh logs       # 查看日志
./scripts/web.sh status     # 查看状态
./scripts/web.sh shell      # 进入容器
./scripts/web.sh composer   # 使用 Composer
```

### 使用 manage.sh

```bash
# 查看帮助
./scripts/manage.sh

# 常用命令
./scripts/manage.sh start
./scripts/manage.sh stop
./scripts/manage.sh restart
./scripts/manage.sh logs
```

### 使用快捷别名

```bash
# 安装快捷别名
./scripts/install-commands.sh

# 使用别名
web-start
web-stop
web-restart
web-logs
web-shell
```

## 🔧 配置说明

### PHP 配置

- **版本**: PHP 8.3
- **扩展**: bcmath, bz2, curl, gd, gettext, gmp, iconv, intl, mbstring, mysqli, opcache, pcntl, pdo, pdo_mysql, pdo_sqlite, posix, shmop, soap, sockets, zip, redis, igbinary
- **Composer**: 已预装
- **配置文件**: `conf/php.ini`

### Nginx 配置

- **版本**: 最新稳定版
- **端口**: 80
- **根目录**: `/www/` (映射到 `/home/app/default/`)
- **配置文件**: `conf/nginx.conf`

### 目录映射

- `/home/app/default/` → `/www/` (网站根目录)
- `./log/` → `/var/log/` (日志目录)
- `./conf/` → 容器内配置文件

## 📦 打包部署

### 创建部署包

```bash
# 创建完整部署包
./scripts/package.sh

# 创建最小部署包
./scripts/package.sh minimal

# 创建配置文件包
./scripts/package.sh configs
```

## 🚀 远程部署

### 交互式远程部署

```bash
# 运行远程部署脚本
./scripts/remote-deploy.sh

# 按提示输入：
# - 服务器 IP 地址
# - SSH 用户名
# - 认证方式（SSH 密钥或密码）
# - 部署包类型
```

### 命令行远程部署

```bash
# 使用 SSH 密钥部署
./scripts/remote-deploy.sh 192.168.1.100 root ~/.ssh/id_rsa

# 使用密码部署
./scripts/remote-deploy.sh 192.168.1.100 ubuntu "" mypassword
```

### 远程管理

```bash
# 交互式远程管理
./scripts/remote-manage.sh

# 命令行远程管理
./scripts/remote-manage.sh 192.168.1.100 root status
./scripts/remote-manage.sh 192.168.1.100 ubuntu logs ~/.ssh/id_rsa
```

### 手动部署到其他服务器

```bash
# 1. 上传部署包到服务器
scp docker-web-env-v1.4.0-minimal.tar.gz user@server:/home/

# 2. 在服务器上解压并部署
tar -xzf docker-web-env-v1.4.0-minimal.tar.gz
cd docker-web-env
./install.sh  # 或 ./deploy.sh
```

## 🌐 访问地址

部署成功后，可以通过以下地址访问：

- **主页**: http://服务器IP:80/
- **健康检查**: http://服务器IP:80/health.php
- **PHP 信息**: http://服务器IP:80/index.php

## 🔍 故障排除

### 查看日志

```bash
# 查看所有服务日志
./scripts/web.sh logs

# 查看特定服务日志
docker compose logs web
docker compose logs -f web  # 实时查看
```

### 常见问题

1. **端口冲突**: 确保 80 端口未被占用
2. **权限问题**: 确保 `/home/app/default/` 目录有正确权限
3. **Docker 未安装**: 运行 `./install.sh` 选择安装 Docker

### 重启服务

```bash
# 重启所有服务
./scripts/web.sh restart

# 重启特定服务
docker compose restart web
```

## 📝 开发说明

### 添加 PHP 扩展

编辑 `build/Dockerfile`，在 `docker-php-ext-install` 部分添加扩展：

```dockerfile
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    bz2 \
    # ... 其他扩展
    your_extension
```

### 修改配置

- **PHP 配置**: 编辑 `conf/php.ini`
- **Nginx 配置**: 编辑 `conf/nginx.conf`
- **PHP-FPM 配置**: 编辑 `conf/php-fpm.conf`

修改后需要重新构建镜像：

```bash
./scripts/web.sh build
./scripts/web.sh restart
```

## 🆕 版本更新

### v1.4.0 新特性

- ✅ 项目结构完全整理，无冗余文件
- ✅ 内置 Composer 和 zip 扩展
- ✅ 统一的部署脚本
- ✅ 交互式安装脚本
- ✅ 清晰的管理命令结构
- ✅ 优化的打包流程

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！