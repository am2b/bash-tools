#!/usr/bin/env bash

#=git-stash
#@移除stash栈上的一个条目

script=$(basename "$0")
arrow="--->"
usage="delete the top stash item from stack"
usage_stash_index="delete the given index of a stash item from stack"

# Usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage"
    echo "$script stash_index $arrow $usage_stash_index"
    exit 1
}

# 检查参数个数或帮助选项
if [[ "$1" == "-h" || $# -gt 1 ]]; then
    usage
fi

# 构建 git stash drop 命令
cmd=("git" "stash" "drop")

# 如果提供了索引参数,则指定stash项目
if [[ $# -eq 1 ]]; then
    stash_index="$1"
    stash_name="stash@{$stash_index}"
    cmd+=("$stash_name")
fi

# 执行命令
"${cmd[@]}"
