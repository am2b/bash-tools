#!/usr/bin/env bash

#=git-tree
#@add的逆操作,恢复到add之前的状态

#恢复到 add 之前的状态

script=$(basename "$0")
arrow="--->"
usage_string="cancel staged, restore to the status before add"
usage_string_files="cancel staged file[s], restore the file[s] to the status before add"

# Usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage_string"
    echo "$script path_to file[s] $arrow $usage_string_files"
    exit 1
}

# 检查是否显示帮助
if [[ "$1" == "-h" ]]; then
    usage
fi

# 构建命令
cmd=("git" "restore" "--staged")

# 如果提供了参数，将其添加到命令中
if [[ $# -gt 0 ]]; then
    for file in "$@"; do
        cmd+=("$file")
    done
else
    cmd+=(".")
fi

# 执行命令
"${cmd[@]}"
