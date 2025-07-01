#!/usr/bin/env bash

#=git-branch
#@删除本地分支,本地的远程分支,远程仓库中的分支

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script branch ---> delete branch in local and in remote repository (if tracked)"
}

while getopts "h" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [[ "$#" -ne 1 ]]; then
    usage
    exit 1
fi

branch="$1"

# 检查当前分支是否就是要删除的分支
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == "$branch" ]]; then
    echo "switching from branch '$branch' to 'master' before deletion."
    git checkout master || { echo "error:failed to switch to 'master'"; exit 1; }
fi

# 检查是否跟踪了远程分支
remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" 2>/dev/null)
if [[ -n "$remote_branch" ]]; then
    echo "deleting remote branch '$remote_branch'"
    git push origin --delete "$branch" || { echo "error:failed to delete remote branch '$branch'"; exit 1; }
fi

# 删除本地分支
#echo "deleting local branch '$branch'"
git branch --delete "$branch" || { echo "error:failed to delete local branch '$branch'.it might be unmerged"; exit 1; }
