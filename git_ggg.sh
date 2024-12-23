#!/usr/bin/env bash

#=git-tools
#@合并git status,diff,add,commit,push
#@usage:script.sh "commit messages"

git status
echo
echo '..............................'
echo

# 检查当前分支是否跟踪远程分支
is_tracking_remote=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

# 根据跟踪状态设置命令
if [[ -n "$is_tracking_remote" ]]; then
    cmd="git add . && git commit -m \"$1\" && git push"
else
    cmd="git add . && git commit -m \"$1\""
fi

git diff --color=always | cat

echo
echo '..............................'
echo

# 检查是否从管道输入
if [[ -p /dev/stdin ]]; then
    # 只读取一次输入,忽略后续的多余输入
    response=$(head -n 1 | tr '[:upper:]' '[:lower:]')
else
    #for distinguishing space and enter
    IFS=

    # 非管道输入时提示用户输入
    echo "continue? [Y/n]"
    read -r -s -n 1 response
    # 将输入转换为小写
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
fi

if [[ "$response" == "y" || -z "$response" ]]; then
    eval "$cmd"
fi
