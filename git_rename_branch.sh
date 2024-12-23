#!/usr/bin/env bash

#=git-branch
#@重命名本地分支,本地的远程分支和远程仓库的分支

script=$(basename "$0")
if [[ "$#" -ne 2 ]]; then
    echo "Usage:"
    echo "$script old_name new_name ---> rename local branch, push new_name branch, and delete old_name branch on remote repository"
    exit 1
fi

old_name="$1"
new_name="$2"

#重命名本地分支
#没有更新本地的远程分支origin/old_name的名称
git branch --move "$old_name" "$new_name"

#将新的分支推送到远程仓库,并设置为当前分支的默认上游分支
#不会移除或更新本地的origin/old_name引用,它依然存在
git push --set-upstream origin "$new_name"

#删除远程仓库中的旧分支
#但本地的origin/old_name仍然存在,且会被标记为gone(失效的引用),因为对应的远程分支已被删除
git push origin --delete "$old_name"

#至此,本地的远程分支origin/old_name并未被重命名或清理

#清理本地的远程分支引用(删除失效的远程分支)
#该命令会同步远程分支的最新状态,删除本地存储中已失效的远程分支引用
#如果远程仓库中的old_name已被删除,那么本地的origin/old_name也会被清理
git fetch --prune

#如何确认远程仓库的状态?
#可以通过以下命令检查远程仓库中的分支状态:
#git ls-remote --heads origin
#如果old_name被删除,输出中将不再显示refs/heads/old_name,仅剩下refs/heads/new_name

#进一步理解远程分支引用
#即便远程仓库中的分支old_name被删除,本地依然可能会保留一个失效的远程分支引用(origin/old_name),这就是为什么需要执行git fetch --prune的原因
#通过以下命令可以查看本地存储的远程分支引用:
#git branch -r
#如果origin/old_name仍然存在且显示为gone,说明它是一个过时的引用,需要清理
