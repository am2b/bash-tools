#!/usr/bin/env bash

#=git-branch
#@基于stash栈顶端的条目创建一个新的分支并切换到该分支,然后删除stash栈顶端的条目

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script branch ---> create a new branch based on the top item of stash and delete that item from stash"
}

if [[ "$1" == "-h" || "$#" -ne 1 ]]; then
    usage
    exit 1
fi

branch_name="$1"

# 基于stash栈顶端的条目创建并切换到新分支
git stash branch "$branch_name"
