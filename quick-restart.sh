#!/bin/bash

# 快速重启守护进程脚本
# 用法: ./quick-restart.sh [进程名]

SCRIPT_DIR="/home/docker-web-env/scripts"
RESTART_SCRIPT="$SCRIPT_DIR/restart-daemon.sh"

# 检查重启脚本是否存在
if [ ! -f "$RESTART_SCRIPT" ]; then
    echo "错误: 重启脚本不存在: $RESTART_SCRIPT"
    exit 1
fi

# 如果没有指定进程名，显示状态
if [ -z "$1" ]; then
    echo "守护进程状态:"
    "$RESTART_SCRIPT" --status
    echo ""
    echo "用法示例:"
    echo "  $0 nginx           # 重启nginx"
    echo "  $0 all             # 重启所有进程" 
    echo "  $0 queue           # 重启所有队列进程"
    echo "  $0 web             # 重启web服务"
    exit 0
fi

# 根据参数执行相应操作
case "$1" in
    "all")
        "$RESTART_SCRIPT" --all
        ;;
    "queue")
        "$RESTART_SCRIPT" --queue
        ;;
    "web")
        "$RESTART_SCRIPT" --web
        ;;
    *)
        "$RESTART_SCRIPT" --restart "$1"
        ;;
esac
