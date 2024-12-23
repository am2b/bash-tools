#!/usr/bin/env bash

#=git-diff
#@查看某个分支和master分支之间的差异(无需提前切换到"某个"分支)
#@查看某个分支的某些文件和master分支之间的差异
#@可以使用普通的diff,或通过-t选项调用difftool(例如nvimdiff)

script_name=$(basename "$0")
arrow="--->"

usage() {
    echo "Usage:"
    echo "$script_name branch_name $arrow diff between branch_name and master"
    echo "$script_name branch_name path/file[s] $arrow diff about specific paths or files"
    echo "$script_name branch_name -t $arrow diff using common tools like difftool"
    echo "$script_name branch_name -t path/file[s] $arrow diff about specific paths or files using difftool"
}

# 解析选项
while getopts "ht" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        t)
            use_tool=true
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

# 参数验证
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

branch_name="$1"
shift

# 确定使用的命令:difftool或diff
cmd="git"
if [[ $use_tool == true ]]; then
    cmd+=" difftool master $branch_name"
else
    cmd+=" diff master $branch_name"
fi

# 如果有文件或路径参数,添加到命令中
if [[ $# -gt 0 ]]; then
    for path in "$@"; do
        cmd+=" $path"
    done
fi

# 执行命令
eval "$cmd"
