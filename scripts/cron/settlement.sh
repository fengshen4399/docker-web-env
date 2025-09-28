#!/bin/bash
# 每日结算脚本
# 执行时间: 每日凌晨0点1分
# 日志位置: /var/log/crontasks/settlement.log

# 设置时区为北京时间
export TZ="Asia/Shanghai"

# 定义date函数简化调用
date_now() {
    date "$@"
}

cd /www

# 日志文件（按日期分离）
LOG_DIR="/var/log/crontasks/$(date_now +%Y)/$(date_now +%m)"
LOG_FILE="$LOG_DIR/settlement-$(date_now +%Y%m%d).log"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 记录开始时间
echo "========================================" >> "$LOG_FILE"
echo "$(date_now): 开始每日结算任务" >> "$LOG_FILE"

# 商户转账
echo "$(date_now): 执行汇率更新..." >> "$LOG_FILE"
if php think update:usdtrate >> "$LOG_FILE" 2>&1; then
    echo "$(date_now): 汇率更新完成" >> "$LOG_FILE"
else
    echo "$(date_now): 汇率更新失败" >> "$LOG_FILE"
fi

# 商户结算
echo "$(date_now): 执行商户结算..." >> "$LOG_FILE"
if php think merchant:settlement >> "$LOG_FILE" 2>&1; then
    echo "$(date_now): 商户结算完成" >> "$LOG_FILE"
else
    echo "$(date_now): 商户结算失败" >> "$LOG_FILE"
fi

# 渠道结算
echo "$(date_now): 执行渠道结算..." >> "$LOG_FILE"
if php think channel:settlement >> "$LOG_FILE" 2>&1; then
    echo "$(date_now): 渠道结算完成" >> "$LOG_FILE"
else
    echo "$(date_now): 渠道结算失败" >> "$LOG_FILE"
fi

# 记录结束时间
echo "$(date_now): 每日结算任务完成" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"