#!/usr/bin/env bash

#=tools
#@clear $HOME/tmp

if ! command -v trash &>/dev/null; then
    echo "this script uses the \"trash\" command."
    exit 1
fi

source_dir="$HOME/tmp"
#获取当前日期时间,格式为YYYY-MM-DD_HH-MM-SS
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
output_file="$source_dir/tmp_$timestamp.tar.gz"

#如果source_dir非空
if [[ -n "$(ls -A "${source_dir}")" ]] && [[ -d "${HOME}"/.trash ]]; then
    #当-C被设置为$source_dir时,tar会将当前工作目录临时切换到$source_dir(只是临时切换目录,而不会真正改变当前shell的工作目录)
    #.:表示只打包切换目录中的内容,而不包含目录本身,这样可以避免打包时引入绝对路径或多余的上层目录,使解压结果更干净,直观
    tar --exclude="$(basename "$output_file")" -czf "$output_file" -C "$source_dir" .

    #mv "${output_file}" "${HOME}"/.trash
    trash "${output_file}"

    #find会从~/tmp开始查找,但由于-mindepth 1,它不会删除~/tmp目录本身,只会删除目录中的内容
    find "${source_dir}" -mindepth 1 -delete
fi
