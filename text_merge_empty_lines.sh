#!/usr/bin/env bash

#=text
#@合并连续的空行,参数可以是一个/多个文件,一个/多个目录,或者文件与目录

#合并空行的函数
merge_empty_lines() {
    local file="$1"

    #检查文件是否存在
    if [[ ! -f "$file" ]]; then
        echo "File '$file' not found!"
        return
    fi

    #使用sed合并空行,将连续的空行合并为一个空行
    sed -i '/^$/N;/^\n$/D' "$file"
}

#如果参数是目录,递归处理目录中的文件
process_directory() {
    local dir="$1"

    #检查目录是否存在
    if [[ ! -d "$dir" ]]; then
        echo "Directory '$dir' not found!"
        return
    fi

    #递归处理所有文件
    find "$dir" -type f -print0 | while IFS= read -r -d $'\0' file; do
        merge_empty_lines "${file}"
    done
}

main() {
    # 遍历所有参数
    for arg in "$@"; do
        # 如果参数是目录,递归处理
        if [[ -d "$arg" ]]; then
            process_directory "$arg"
        # 如果是文件,直接处理
        elif [[ -f "$arg" ]]; then
            merge_empty_lines "$arg"
        else
            echo "'$arg' is not a valid file or directory"
        fi
    done
}

main "$@"

#sed -i '/^$/N;/^\n$/D' "$file"
#/^$/:匹配空行
#N:将下一行添加到模式空间(将当前行和下一行一起处理)
#/^\n$/:匹配由两个换行符组成的空行对
#D:删除第一个换行符,从而删除连续的空行
