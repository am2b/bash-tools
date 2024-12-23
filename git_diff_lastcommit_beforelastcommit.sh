#!/usr/bin/env bash

#=git-diff
#@查看上次提交和上上次提交之间的差异

function usage() {
    local script_name=$(basename "$0")
    echo "Usage:"
    echo "$script_name ---> diff between last commit and before last commit"
    echo "$script_name path/file[s] ---> diff between last commit and before last commit about path/file[s]"
    echo "$script_name -t ---> diff between last commit and before last commit using common diff tools like nvimdiff"
    echo "$script_name -t path/file[s] ---> diff between last commit and before last commit about path/file[s] using common diff tools"
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

cmd="git $tool HEAD^ HEAD"

# 如果有附加路径或文件参数,则添加到命令中
if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        cmd+=" $arg"
    done
fi

# 执行命令
eval "$cmd"
