#!/usr/bin/env bash

#=git-diff
#@查看工作区和暂存区之间的差异
#@注意:无法对untracked files进行比较

arrow="--->"
script=$(basename "$0")
usage_string="diff between working tree and index(staged)"
usage_path="path/file[s]"
usage_tool="use common diff tools like nvimdiff"

usage() {
    echo "Usage:"
    echo "$script $arrow $usage_string"
    echo "$script $usage_path $arrow $usage_string about $usage_path"
    echo "$script -t $arrow $usage_string, $usage_tool"
    echo "$script -t $usage_path $arrow $usage_string about $usage_path, $usage_tool"
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
        *) 
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

cmd="git $tool"
if [[ $# -gt 0 ]]; then
    for path in "$@"; do
        cmd+=" $path"
    done
fi

eval "$cmd"
