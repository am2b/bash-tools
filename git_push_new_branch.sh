#!/usr/bin/env bash

#=git-push
#@把本地新建的分支给push到远程仓库
#@无需手动检出被push的分支

usage() {
    echo "Usage:"
    echo "$(basename "$0") branch ---> push branch to remote repository"
}

while getopts ":h" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))
if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

branch="$1"

#检查是否已经在目标分支
current_branch=$(git symbolic-ref --short HEAD)
if [[ "$current_branch" != "$branch" ]]; then
    git checkout "$branch" || { echo "Failed to switch to branch $branch"; exit 1; }
fi

#将当前所在的本地分支推送到远程仓库,并设置其上游分支为远程仓库的相同分支
git push --set-upstream origin "$branch"

#再把分支切换回去
if [[ "$current_branch" != "$branch" ]]; then
    git checkout "$current_branch" || { echo "Failed to switch to branch $current_branch"; exit 1; }
fi

#运行成功后,使用以下命令验证推送的分支:
#git branch -vv
#可以看到本地分支feature-branch显示为跟踪远程的origin/feature-branch分支
