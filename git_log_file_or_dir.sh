#!/usr/bin/env bash

#=git-log
#@打印给定文件或目录的log
#@usage:
#@script.sh file
#@script.sh dir

script=$(basename "$0")
arrow="--->"
usage_default="limit the log output to commits that introduced a change to a file or a dir"

# Usage function
usage() {
    echo "Usage:"
    echo "$script 'file_or_dir' $arrow $usage_default"
    exit 1
}

# 检查参数数量
if [[ $# -ne 1 ]]; then
    usage
fi

# 获取路径参数
path="$1"

if [[ ! -e "$path" ]]; then
    echo "Error:'$path' does not exist"
    exit 1
fi

# 执行命令
cmd="git log --oneline --decorate --patch --graph --all -- $path"
eval "$cmd"
