# 守护进程重启功能说明

本项目新增了完善的守护进程管理和重启功能，支持对supervisor管理的各种守护进程进行灵活的重启操作。

## 功能概述

项目包含以下守护进程：
- **nginx**: Web服务器
- **php-fpm**: PHP-FPM进程管理器
- **default**: 默认队列工作进程
- **order_notify**: 订单通知队列进程
- **order_query**: 订单查询队列进程
- **usdt_transfer**: USDT转账队列进程

## 使用方式

### 1. 专用守护进程重启脚本

**脚本位置**: `/home/docker-web-env/scripts/restart-daemon.sh`

#### 基本用法：
```bash
# 查看帮助
./scripts/restart-daemon.sh --help

# 查看所有守护进程状态
./scripts/restart-daemon.sh --status

# 重启指定进程
./scripts/restart-daemon.sh --restart nginx
./scripts/restart-daemon.sh --restart php-fpm

# 强制重启进程（先停止再启动）
./scripts/restart-daemon.sh --force order_notify

# 重启所有进程
./scripts/restart-daemon.sh --all

# 重启所有队列工作进程
./scripts/restart-daemon.sh --queue

# 重启Web服务（nginx + php-fpm）
./scripts/restart-daemon.sh --web
```

### 2. 集成管理脚本

**脚本位置**: `/home/docker-web-env/scripts/manage.sh`

#### 新增命令：
```bash
# 守护进程管理（传递参数给restart-daemon.sh）
./scripts/manage.sh daemon --status
./scripts/manage.sh daemon --restart nginx
./scripts/manage.sh daemon --queue
./scripts/manage.sh daemon --all

# 快速重启所有队列进程
./scripts/manage.sh queue
```

### 3. 快速重启脚本

**脚本位置**: `/home/docker-web-env/quick-restart.sh`

#### 简化用法：
```bash
# 查看状态和用法
./quick-restart.sh

# 重启指定进程
./quick-restart.sh nginx
./quick-restart.sh php-fpm
./quick-restart.sh order_notify

# 快速操作
./quick-restart.sh all       # 重启所有进程
./quick-restart.sh queue     # 重启所有队列进程
./quick-restart.sh web       # 重启web服务
```

## 功能特性

### 🎨 彩色日志输出
- **蓝色**: 信息提示
- **绿色**: 成功操作
- **黄色**: 警告信息
- **红色**: 错误信息

### 🔍 智能检查
- 自动检查supervisor是否运行
- 验证进程是否存在
- 重启后自动验证进程状态

### 🚀 批量操作
- 支持按类型批量重启（队列、Web服务）
- 支持重启所有进程
- 强制重启模式

### 📊 状态监控
- 实时显示进程状态
- 重启后状态验证
- 详细的错误报告

## 使用场景

### 1. 日常维护
```bash
# 检查所有进程状态
./quick-restart.sh

# 重启有问题的队列进程
./quick-restart.sh order_notify
```

### 2. 配置更新后
```bash
# 重启Web服务应用新配置
./scripts/restart-daemon.sh --web

# 或使用管理脚本
./scripts/manage.sh daemon --web
```

### 3. 批量重启
```bash
# 重启所有队列进程
./scripts/manage.sh queue

# 重启所有进程
./quick-restart.sh all
```

### 4. 故障排查
```bash
# 强制重启有问题的进程
./scripts/restart-daemon.sh --force order_query

# 查看详细状态
./scripts/restart-daemon.sh --status
```

## 注意事项

1. **权限要求**: 建议以root权限运行以确保所有功能正常
2. **依赖检查**: 脚本会自动检查supervisor是否运行
3. **进程验证**: 重启后会自动验证进程状态
4. **错误处理**: 提供详细的错误信息和建议

## 文件权限

所有脚本文件已设置为777权限，确保可执行：
- `/home/docker-web-env/scripts/restart-daemon.sh` (777)
- `/home/docker-web-env/quick-restart.sh` (777)
- `/home/docker-web-env/scripts/manage.sh` (777)

## 扩展

如需添加新的守护进程，请：
1. 在supervisor配置中添加新进程
2. 更新`restart-daemon.sh`中的进程列表
3. 根据需要添加到相应的批量操作中

---

*更新时间: 2025年9月26日*