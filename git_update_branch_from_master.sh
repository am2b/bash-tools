#!/usr/bin/env bash

#=git-branch
#@usage:
#@script.sh branch
#@当master包含了branch分支里面的所有提交,并且master还具有branch分支里面所没有的提交,这时候就可以根据master来更新branch分支

script=$(basename "$0")
arrow="--->"
usage="update branch from master"

usage() {
    echo "Usage:"
    echo "$script branch $arrow $usage"
    exit 1
}

while getopts "h" opt; do
    case $opt in
    h)
        usage
        ;;
    *)
        # 处理不支持的选项
        echo "error:unsupported option -$opt"
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if (($# != 1)); then
    usage
fi

# 检查当前是否在Git仓库中
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "错误:当前目录不是一个Git仓库"
    exit 1
fi

branch="$1"

# 确保master分支和参数分支都存在
if ! git rev-parse --verify master >/dev/null 2>&1; then
    echo "error: 'master' branch does not exist"
    exit 1
fi
if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "error: '$branch' branch does not exist"
    exit 1
fi

# 检查master是否包含参数分支的所有提交
if ! git merge-base --is-ancestor "$branch" master; then
    echo "master branch does not contain all commits from '$branch'"
    exit 1
fi

# 检查master是否有参数分支中没有的提交
if git merge-base --is-ancestor master "$branch"; then
    echo "master branch has no additional commits beyond '$branch'"
    exit 1
fi

#获取当前分支名
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "$branch" ]]; then
    git checkout "${branch}"
fi
git merge master

if [[ "$current_branch" != "$branch" ]]; then
    git checkout "${current_branch}"
fi
