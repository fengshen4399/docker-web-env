# Cron脚本使用指南

## 概述

为了更好地处理复杂的定时任务，我们支持两种方式：
1. **单行命令方式** - 适用于简单任务
2. **脚本文件方式** - 适用于多行命令、复杂逻辑的任务

## 脚本目录结构

```
scripts/cron/
├── comprehensive_monitor.sh    # 综合监控脚本
├── backup.sh                   # 数据备份脚本
├── queue_worker.sh            # 队列处理脚本
└── [自定义脚本].sh            # 你的自定义脚本
```

## 创建新的Cron脚本

### 1. 创建脚本文件

在 `scripts/cron/` 目录下创建新的 `.sh` 文件：

```bash
# 示例：创建用户统计脚本
cat > scripts/cron/user_stats.sh << 'EOF'
#!/bin/bash
# 用户统计脚本
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /www

LOG_FILE="/var/log/crontasks/user_stats.log"

echo "$(date): 开始用户统计" >> "$LOG_FILE"

# 统计今日注册用户
TODAY_USERS=$(php think user:count --today)
echo "$(date): 今日注册用户: $TODAY_USERS" >> "$LOG_FILE"

# 统计活跃用户
ACTIVE_USERS=$(php think user:count --active)
echo "$(date): 活跃用户: $ACTIVE_USERS" >> "$LOG_FILE"

# 生成统计报告
php think report:generate --type=user >> "$LOG_FILE" 2>&1

echo "$(date): 用户统计完成" >> "$LOG_FILE"
EOF

# 设置执行权限
chmod +x scripts/cron/user_stats.sh
```

### 2. 在crontab-template.conf中添加任务

```bash
# 每小时执行用户统计
0 * * * * /usr/local/bin/cron-scripts/user_stats.sh
```

### 3. 重新加载配置

```bash
./scripts/manage.sh cron
```

## 脚本编写规范

### 基本模板

```bash
#!/bin/bash
# 脚本描述
# 执行时间: [执行频率]
# 功能: [功能描述]

# 设置环境变量
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /www

# 日志文件
LOG_FILE="/var/log/crontasks/[脚本名].log"

echo "$(date): 开始执行任务" >> "$LOG_FILE"

# 你的具体逻辑
# 命令1
# 命令2
# 命令3

echo "$(date): 任务执行完成" >> "$LOG_FILE"
```

### 最佳实践

1. **错误处理**
```bash
# 遇到错误立即退出
set -e

# 或者单独处理每个命令
if php think some:command >> "$LOG_FILE" 2>&1; then
    echo "$(date): 命令执行成功" >> "$LOG_FILE"
else
    echo "$(date): 命令执行失败" >> "$LOG_FILE"
fi
```

2. **超时控制**
```bash
# 限制命令执行时间（5分钟）
timeout 300 php think long:running:task >> "$LOG_FILE" 2>&1
```

3. **日志格式**
```bash
# 统一的日志格式
echo "========================================" >> "$LOG_FILE"
echo "$(date): [任务名] 开始" >> "$LOG_FILE"
# ... 执行内容 ...
echo "$(date): [任务名] 完成" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
```

## 现有脚本说明

### comprehensive_monitor.sh
- **功能**: 综合监控（支付、渠道、预付费、商户余额）
- **执行时间**: 每5分钟
- **日志**: `/var/log/crontasks/comprehensive_monitor.log`

### backup.sh
- **功能**: 数据备份（应用文件、配置文件）
- **执行时间**: 每天凌晨3点
- **日志**: `/var/log/crontasks/backup.log`
- **备份位置**: `/var/log/crontasks/backups/`

### queue_worker.sh
- **功能**: 队列任务处理
- **执行时间**: 每10分钟
- **日志**: `/var/log/crontasks/queue.log`

## 热更新机制

使用脚本方式的优势：
1. **热更新**: 修改脚本文件后无需重建容器
2. **版本控制**: 脚本文件可以纳入Git管理
3. **复用性**: 脚本可以手动执行测试
4. **维护性**: 复杂逻辑更容易维护

### 更新流程

1. 修改 `scripts/cron/` 目录下的脚本文件
2. 如需新增任务，更新 `crontab-template.conf`
3. 执行 `./scripts/manage.sh cron` 重新加载

## 调试和测试

### 手动执行脚本
```bash
# 进入容器测试脚本
sudo docker exec my_web /usr/local/bin/cron-scripts/comprehensive_monitor.sh

# 或在宿主机直接测试
bash scripts/cron/comprehensive_monitor.sh
```

### 查看日志
```bash
# 实时查看日志
sudo docker exec my_web tail -f /var/log/crontasks/comprehensive_monitor.log

# 查看所有cron相关日志
sudo docker exec my_web ls -la /var/log/crontasks/
```

### 检查任务状态
```bash
# 查看当前cron任务
./scripts/manage.sh cron

# 检查cron服务状态
sudo docker exec my_web supervisorctl status cron
```