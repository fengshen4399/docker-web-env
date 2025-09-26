# 守护进程管理功能集成说明

## 概述

已成功将Docker容器守护进程重启功能集成到项目的三个主要管理脚本中，提供统一的进程管理接口。

## 集成的脚本

### 1. scripts/manage.sh - 核心管理脚本

#### 新增命令：

**守护进程管理**
```bash
# 完整的守护进程管理
./scripts/manage.sh daemon [选项]

# 支持的选项：
  -s, --status     显示所有进程状态
  -a, --all        重启所有进程
  -q, --queue      重启队列进程
  -w, --web        重启Web服务
  -r <name>        重启指定进程
  -f <name>        强制重启指定进程
  -h, --help       显示帮助

# 示例：
./scripts/manage.sh daemon -s          # 显示进程状态
./scripts/manage.sh daemon -r nginx    # 重启nginx
./scripts/manage.sh daemon -q          # 重启所有队列
```

**快速状态查看**
```bash
# 显示supervisor状态
./scripts/manage.sh supervisor

# 显示容器内所有进程
./scripts/manage.sh processes
```

### 2. scripts/web.sh - Web环境管理脚本

#### 新增命令：

**交互式守护进程管理菜单**
```bash
./scripts/web.sh daemon
# 进入交互式菜单，包含：
# 1) 显示进程状态
# 2) 重启所有进程  
# 3) 重启队列进程
# 4) 重启Web服务
# 5) 重启指定进程
# 6) 返回主菜单
```

**快捷命令**
```bash
./scripts/web.sh queue        # 重启队列进程
./scripts/web.sh supervisor   # 显示进程状态  
./scripts/web.sh restart-all  # 重启所有进程
```

### 3. install.sh - 交互式安装脚本

#### 新增菜单项：

在主菜单中增加了第13项：
```
13) ⚙️ 守护进程管理
```

提供交互式守护进程管理界面，包含：
- 显示进程状态
- 重启所有进程
- 重启队列进程
- 重启Web服务
- 重启指定进程
- 强制重启指定进程
- 显示帮助信息

## 管理的进程

### Web服务进程
- **nginx** - Nginx Web服务器
- **php-fpm** - PHP-FPM进程管理器

### 队列工作进程
- **default:*** - 默认队列工作进程
- **order_notify:*** - 订单通知进程
- **order_query:*** - 订单查询进程  
- **usdt_transfer:*** - USDT转账进程

## 使用示例

### 1. 快速查看所有进程状态
```bash
# 方法1：使用manage.sh
./scripts/manage.sh supervisor

# 方法2：使用web.sh
./scripts/web.sh supervisor

# 方法3：使用详细的daemon命令
./scripts/manage.sh daemon -s
```

### 2. 重启特定服务
```bash
# 重启Web服务
./scripts/manage.sh daemon -w
./scripts/web.sh daemon # 选择菜单项4

# 重启队列进程
./scripts/manage.sh daemon -q
./scripts/web.sh queue

# 重启nginx
./scripts/manage.sh daemon -r nginx
```

### 3. 重启所有进程
```bash
# 方法1：使用manage.sh
./scripts/manage.sh daemon -a

# 方法2：使用web.sh
./scripts/web.sh restart-all

# 方法3：通过交互菜单
./scripts/web.sh daemon # 选择菜单项2
```

## 技术特性

### 容器化支持
- 所有命令都通过 `sudo docker exec my_web supervisorctl` 执行
- 自动检查容器运行状态
- 支持容器内supervisor进程组管理

### 错误处理
- 容器状态检查
- Supervisor连接状态验证
- 进程存在性验证
- 详细的错误提示和日志

### 兼容性
- 保持原有脚本功能不变
- 新增功能向后兼容
- 支持多种调用方式

## 权限要求

- 需要sudo权限执行Docker命令
- 建议以admin用户运行
- 脚本会自动提示权限相关警告

## 日志输出

所有守护进程操作都包含：
- 彩色状态提示 (成功/警告/错误)
- 详细的操作日志
- 进程运行时间和PID信息
- 操作前后的状态对比

## 故障排除

如果遇到权限问题：
```bash
# 确保当前用户有sudo权限
sudo -v

# 检查Docker容器状态
sudo docker ps | grep my_web

# 检查supervisor状态
sudo docker exec my_web supervisorctl status
```

## 扩展功能

可以通过修改 `scripts/restart-daemon.sh` 来添加更多进程管理功能，所有集成的脚本都会自动继承这些新功能。