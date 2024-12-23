#!/usr/bin/env bash

#=tools
#@移除文件的后缀名

#移除脚本文件的后缀名
if (($# < 1)); then
    echo Usage:command file1.aa file2.bb ...
    exit 1
fi

for file in "$@"; do
    if [[ -f $file ]]; then
        mv "$file" "${file%.*}"
    fi
done
