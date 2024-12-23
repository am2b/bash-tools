#!/usr/bin/env bash

#=git-stash
#@stash工作区的修改,和index的修改

script=$(basename "$0")
arrow="--->"
usage="stash working tree and index"
usage_message="stash working tree and index with message"

# Usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage"
    echo "$script message $arrow $usage_message"
    exit 1
}

# 检查参数数量或是否显示帮助
if [[ "$1" == "-h" || $# -gt 1 ]]; then
    usage
fi

# 构建命令
cmd=("git" "stash")

# 如果提供了message参数,附加到命令中
if [[ $# -eq 1 ]]; then
    message="$1"
    cmd+=("--message" "$message")
fi

# 执行命令
"${cmd[@]}"
