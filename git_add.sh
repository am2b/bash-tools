#!/usr/bin/env bash

#=git-tree
#@add.sh:添加文件到git仓库
#@支持以下选项和参数:
#@-u:添加已跟踪的修改过的文件
#@不加参数:添加所有跟踪和未跟踪的文件
#@参数为文件路径时:添加指定路径的文件

# Usage 函数,显示用法说明
usage() {
    echo "Usage:"
    echo "add.sh -u ---> add update tracked files"
    echo "add.sh path_a/file_a path_b/file_b ---> add path_a/file_a path_b/file_b"
    echo "add.sh ---> add all tracked and untracked files"
}

# 解析命令行参数
while getopts ":hu" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        u)
            update_flag=true
            ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# 移动到非选项参数(文件路径)
shift $((OPTIND - 1))

# 检查是否有-u和路径同时存在(不允许同时存在)
if [[ "$update_flag" == true && $# -gt 0 ]]; then
    echo "Error: -u option cannot be used with file paths." >&2
    exit 1
fi

# 执行git命令的函数
_add() {
    eval "$1"
}

# 如果使用了-u
if [[ "$update_flag" == true ]]; then
    _add "git add --update"
    exit 0
fi

# 如果没有路径参数,默认添加所有文件
if [[ $# -eq 0 ]]; then
    _add "git add --all"
    exit 0
fi

# 如果有路径参数,逐一添加
for path in "$@"; do
    _add "git add \"$path\""
done

#git add命令使用文件或目录的路径作为参数.如果参数是目录的路径,该命令将递归地跟踪该目录下的所有文件
#这是个多功能命令:可以用它开始跟踪新文件,或者把已跟踪的文件放到暂存区,还能用于合并时把有冲突的文件标记为已解决状态等
#将这个命令理解为"精确地将内容添加到下一次提交中"而不是"将一个文件添加到项目中"要更加合适
