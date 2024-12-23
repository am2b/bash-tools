#!/usr/bin/env bash

#=git-log
#@给定一个字符串,找到该字符串被添加,删除,修改的全部提交
#@usage:
#@script.sh "some_string"

script=$(basename "$0")
arrow="--->"
usage_default="to find commits that added or removed or changed the given 'string'"

# Usage function
usage() {
    echo "Usage:"
    echo "$script 'string' $arrow $usage_default"
    exit 1
}

# 检查参数数量
if [[ $# -ne 1 ]]; then
    usage
fi

# 获取要查找的字符串
to_find="$1"

# 构造并执行命令
cmd="git log -G \"$to_find\" --oneline --decorate --patch --graph --all"
eval "$cmd"
