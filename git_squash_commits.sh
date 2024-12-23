#!/usr/bin/env bash

#=git-commit
#@压缩给定数量的提交为一个提交

usage() {
    echo "Usage:"
    echo "$(basename "$0") num_of_commits ---> squash the given number of commits"
    echo "$(basename "$0") num_of_commits commit_message ---> squash the given number of commits with a message"
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
    usage
    exit 1
fi

num_of_commits="$1"
commit_message=""
if [[ $# -eq 2 ]]; then
    commit_message="$2"
fi

# 检查提交数量是否为正整数
if ! [[ "$num_of_commits" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: <num_of_commits> must be a positive integer."
    usage
    exit 1
fi

# 获取当前分支的提交总数
total_commits=$(git rev-list --count HEAD)
if [[ $? -ne 0 ]]; then
    echo "error:failed to retrieve commit count.are you in a git repository?"
    exit 1
fi

# 检查num_of_commits是否小于等于total_commits
if (( num_of_commits > total_commits )); then
    echo "error:num_of_commits:$num_of_commits exceeds total commits $total_commits on the current branch"
    exit 1
fi

#使用HEAD~<num_of_commits>回退指定数量的提交,但保留修改(软重置)
git reset --soft HEAD~"$num_of_commits"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to reset commits."
    exit 1
fi

if [[ -n "$commit_message" ]]; then
    git commit -m "$commit_message"
else
    git commit
fi

#^:
#表示字符串的起始位置
#确保从头开始匹配,不允许匹配到中间的数字
#[1-9]:
#匹配一个数字,范围是1到9
#确保输入的数字以非零数字开头,这样可以避免如012这样的无效输入
#[0-9]*:
#匹配任意个(包括0个)数字,范围是0到9
#*是量词,表示匹配前面的字符组零次或多次
#这允许匹配输入的数字有多位,例如10,12345等
#$:
#表示字符串的结束位置
#确保整个字符串匹配正则表达式,不允许有额外字符(例如123a不会匹配)
