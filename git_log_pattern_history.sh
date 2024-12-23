#!/usr/bin/env bash

#=git-log
#@基于一个正则表达式来打印某个文件中一行代码或者一个函数的历史
#@usage:
#@script.sh /pattern/ file
#@script.sh /function_name/ file

script=$(basename "$0")
arrow="--->"
usage="log the history of a line or a function in a file, based on a pattern (like: /some_function_name/)"

# Usage function
usage() {
    echo "Usage:"
    echo "$script pattern file_path $arrow $usage"
    exit 1
}

# 检查参数数量是否正确
if [[ $# -ne 2 ]]; then
    usage
fi

# 获取参数
pattern="$1"
file_path="$2"

# 构造命令
cmd="git log -L $pattern:$file_path"

# 执行命令
eval "$cmd"
