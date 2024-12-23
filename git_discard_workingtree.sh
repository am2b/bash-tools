#!/usr/bin/env bash

#=git-tree
#@用于丢弃工作区的修改,并恢复到上次提交或索引的状态

script="discard_workingtree.sh"
arrow="--->"
usage_string="discard changes in working tree, restore to last commit, or same as indexed"
usage_string_files="discard changes in some file[s], restore to last commit, or same as indexed"

# 显示使用说明
usage() {
    echo "Usage:"
    echo "$script $arrow $usage_string"
    echo "$script path_to_file[s] $arrow $usage_string_files"
}

# 解析选项
while getopts ":h" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# 移动到非选项参数
shift $((OPTIND - 1))

# 构建 git restore 命令
cmd="git restore"

if [[ $# -gt 0 ]]; then
    # 如果有路径参数，将路径依次添加到命令
    for file in "$@"; do
        cmd+=" \"$file\""
    done
else
    # 如果没有路径参数，恢复整个工作区
    cmd+=" ."
fi

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

#丢弃工作区修改
#1,如果暂存区没有记录，那么就把工作区的文件恢复到和上次提交的记录一样
#2,如果暂存区有记录，那么就把工作区的文件恢复到和暂存区的记录一样

#to restore all files in the current directory:
#git restore .
#to restore all working tree files with top pathspec magic:
#git restore :/
