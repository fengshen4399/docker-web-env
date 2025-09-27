#!/bin/bash
# 每日结算脚本
# 执行时间: 每日凌晨0点1分
# 日志位置: /var/log/crontasks/settlement.log

cd /www

# 日志文件（按日期分离）
LOG_DIR="/var/log/crontasks/$(date +%Y)/$(date +%m)"
LOG_FILE="$LOG_DIR/settlement-$(date +%Y%m%d).log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 记录开始时间
echo "========================================" >> "$LOG_FILE"
echo "$(date): 开始每日结算任务" >> "$LOG_FILE"

# 商户转账
echo "$(date): 执行汇率更新..." >> "$LOG_FILE"
if php think update:usdtrate >> "$LOG_FILE" 2>&1; then
    echo "$(date): 汇率更新完成" >> "$LOG_FILE"
else
    echo "$(date): 汇率更新失败" >> "$LOG_FILE"
fi

# 商户结算
echo "$(date): 执行商户结算..." >> "$LOG_FILE"
if php think merchant:settlement >> "$LOG_FILE" 2>&1; then
    echo "$(date): 商户结算完成" >> "$LOG_FILE"
else
    echo "$(date): 商户结算失败" >> "$LOG_FILE"
fi

# 渠道结算
echo "$(date): 执行渠道结算..." >> "$LOG_FILE"
if php think channel:settlement >> "$LOG_FILE" 2>&1; then
    echo "$(date): 渠道结算完成" >> "$LOG_FILE"
else
    echo "$(date): 渠道结算失败" >> "$LOG_FILE"
fi

# 记录结束时间
echo "$(date): 每日结算任务完成" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"