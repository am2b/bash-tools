#!/usr/bin/env bash

#=git-stash
#@应用stash,然后删除栈上的条目

script=$(basename "$0")
arrow="--->"
usage="apply the top stash item and delete from stack"
usage_stash_index="apply the given index of a stash item and delete from stack"

# Usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage"
    echo "$script stash_index $arrow $usage_stash_index"
    exit 1
}

# 检查是否有 -h 或多余参数
if [[ "$1" == "-h" || $# -gt 1 ]]; then
    usage
fi

# 构建命令
cmd=("git" "stash" "pop" "--index")

# 如果提供了stash索引,则指定stash项目
if [[ $# -eq 1 ]]; then
    stash_index="$1"
    stash_name="stash@{$stash_index}"
    cmd+=("$stash_name")
fi

# 执行命令
"${cmd[@]}"
