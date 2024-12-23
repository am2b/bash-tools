#!/usr/bin/env bash

#=git-diff
#@查看当前分支和master分支之间的差异
#@查看当前分支的某些文件和master分支之间的差异
#@可以使用普通的diff,或通过-t选项调用difftool(例如nvimdiff)

function usage() {
    local script_name=$(basename "$0")
    echo "Usage:"
    echo "$script_name ---> diff between current branch and master"
    echo "$script_name path/file[s] ---> diff between current branch and master about path/file[s]"
    echo "$script_name -t ---> diff between current branch and master using common diff tools like nvimdiff"
    echo "$script_name -t path/file[s] ---> diff between current branch and master about path/file[s] using common diff tools"
}

tool="diff"
while getopts ":ht" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        t)
            tool="difftool"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

cmd="git $tool master"

# 如果有附加路径或文件参数,则添加到命令中
if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        cmd+=" $arg"
    done
fi

eval "$cmd"
