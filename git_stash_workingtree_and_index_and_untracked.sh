#!/usr/bin/env bash

#=git-stash
#@stash工作区的修改,index的修改和未被跟踪的修改,但是没有stash被ignore的文件

script=$(basename "$0")
arrow="--->"
usage="stash working tree and index and untracked"
usage_message="stash working tree and index and untracked with message"

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
cmd=("git" "stash" "--include-untracked")

# 如果提供了 message 参数，附加到命令中
if [[ $# -eq 1 ]]; then
    message="$1"
    cmd+=("--message" "$message")
fi

# 执行命令
"${cmd[@]}"
