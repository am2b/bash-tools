#!/usr/bin/env bash

#=git-log
#@打印给定数量的log

script=$(basename "$0")
arrow="--->"
usage_default="print 3 entries with difference"
usage_num="print the num of entries with difference"

usage() {
    echo "Usage:"
    echo "$script $arrow $usage_default"
    echo "$script num $arrow $usage_num"
    exit 1
}

if [[ $# -gt 1 ]]; then
    usage
fi

# 默认日志条数
log_num=3

# 如果提供了参数,则使用该参数作为日志条数
if [[ $# -eq 1 ]]; then
    log_num="$1"
    # 验证是否为有效的数字
    if ! [[ "$log_num" =~ ^[0-9]+$ ]]; then
        echo "Error: num must be a positive integer"
        usage
    fi
fi

# 构造并执行命令
cmd="git log --oneline --decorate --patch --graph --all -${log_num}"
eval "$cmd"
