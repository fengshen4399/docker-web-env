#!/bin/bash
# 综合监控脚本 - 包含支付、渠道、预付费、商户余额监控
# 执行时间: 每5分钟
# 日志位置: /var/log/crontasks/monitor.log

cd /www

# 日志文件（按日期分离）
LOG_DIR="/var/log/crontasks/$(date +%Y)/$(date +%m)"
LOG_FILE="$LOG_DIR/monitor-$(date +%Y%m%d).log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 记录开始时间
echo "========================================" >> "$LOG_FILE"
echo "$(date): 开始综合监控任务" >> "$LOG_FILE"

# 1. 支付状态监控
echo "$(date): 执行支付状态监控..." >> "$LOG_FILE"
if php think payment:status:monitor >> "$LOG_FILE" 2>&1; then
    echo "$(date): 支付状态监控完成" >> "$LOG_FILE"
else
    echo "$(date): 支付状态监控失败" >> "$LOG_FILE"
fi

# 2. 渠道余额监控
echo "$(date): 执行渠道余额监控..." >> "$LOG_FILE"
if php think channel:balance:monitor >> "$LOG_FILE" 2>&1; then
    echo "$(date): 渠道余额监控完成" >> "$LOG_FILE"
else
    echo "$(date): 渠道余额监控失败" >> "$LOG_FILE"
fi

# 3. 预付费余额监控
echo "$(date): 执行预付费余额监控..." >> "$LOG_FILE"
if php think prepaid:balance:monitor >> "$LOG_FILE" 2>&1; then
    echo "$(date): 预付费余额监控完成" >> "$LOG_FILE"
else
    echo "$(date): 预付费余额监控失败" >> "$LOG_FILE"
fi

# 4. 商户余额监控
echo "$(date): 执行商户余额监控..." >> "$LOG_FILE"
if php think merchant:balance:monitor >> "$LOG_FILE" 2>&1; then
    echo "$(date): 商户余额监控完成" >> "$LOG_FILE"
else
    echo "$(date): 商户余额监控失败" >> "$LOG_FILE"
fi

# 记录结束时间
echo "$(date): 综合监控任务完成" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"