#!/usr/bin/env bash

#=git-stash
#@查看stash栈

script=$(basename "$0")
arrow="--->"
usage="list stash"

# Usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage"
    exit 1
}

# 检查是否有 -h 或额外参数
if [[ "$1" == "-h" || $# -ne 0 ]]; then
    usage
fi

# 执行 git stash list 命令
git stash list | bat --style=grid
