#!/usr/bin/env bash

#=text
#@删除掉文本文件末尾的一行或多行空行
#@usage:
#@script.sh file.txt

if (($# != 1)); then
    exit 1
fi

file="${1}"

if [ ! -f "$file" ]; then
    exit 1
fi

if file "$file" | grep -q 'text'; then
    #先删除掉空白字符
    sed -i -e 's/[[:space:]]*$//' "${file}"
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${file}"
fi
