#!/usr/bin/env bash

#=git-branch
#@基于远程仓库的某个分支,在本地创建一个新的分支并切换到该分支

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script branch ---> create and checkout a local branch based on a remote branch"
}

if [[ "$1" == "-h" || "$#" -ne 1 ]]; then
    usage
    exit 1
fi

branch_name="$1"

#更新所有远程分支信息
git fetch --all

#git checkout -b <branch> <remote>/<branch>
#git checkout --track origin/serverfix
#如果你尝试检出的分支不存在且刚好只有一个名字与之匹配的远程分支,那么Git就会为你创建一个跟踪分支：
#git checkout serverfix

#创建本地分支并切换
git checkout -b "$branch_name" "origin/$branch_name"
