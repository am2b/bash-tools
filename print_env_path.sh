#!/usr/bin/env bash

#=tools
#@print $PATH

# 获取PATH变量并按":"分隔
IFS=':' read -r -a paths <<< "$PATH"

# 使用关联数组记录出现的路径及其计数
declare -A seen
output=""

for path in "${paths[@]}"; do
    # 如果路径是$HOME的子路径,替换为~
    if [[ $path == $HOME* ]]; then
        path="~${path#$HOME}"
    fi

    # 检查路径是否重复
    if [[ -n ${seen[$path]} ]]; then
        output+="$path (duplicate)\n"
    else
        output+="$path\n"
        seen[$path]=1
    fi
done

printf "$output"
