#!/usr/bin/env bash

#=git-branch
#@基于本地仓库的某个分支,在本地创建一个新的分支并切换到该分支
#@usage:
#@script.sh local_branch new_branch
#@无需提前切换到local_branch

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <local_branch> <new_branch>"
    exit 1
fi

local_branch="$1"
new_branch="$2"

# 确保该脚本在一个Git仓库中运行
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "error: not a git repository"
    exit 1
fi

# 检查local_branch是否存在
if ! git show-ref --verify --quiet "refs/heads/$local_branch"; then
    echo "error: branch '$local_branch' does not exist"
    exit 1
fi

# 检查new_branch是否已存在
if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    echo "error: branch '$new_branch' already exists"
    exit 1
fi

# 基于指定的local_branch创建并切换到new_branch,即使当前所在分支不是local_branch也可以
if ! git checkout -b "$new_branch" "$local_branch"; then
    echo "error: failed to create and checkout branch '$new_branch'"
    exit 1
fi

# 打印本地分支明细
git branch -vv | bat --style=grid
