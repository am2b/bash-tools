#!/usr/bin/env bash

#=tools
#@smart cp

#复制文件或目录,并保留原有属性
copy_item() {
    local item="$1"
    local dest="$2"

    if [[ -f "$item" ]]; then
        cp -p "$item" "$dest" || { echo "复制文件 '$item' 失败"; exit 1; }
    elif [[ -d "$item" ]]; then
        cp -rp "$item" "$dest" || { echo "复制目录 '$item' 失败"; exit 1; }
    else
        echo "警告:'$item' 既不是文件也不是目录,跳过..."
    fi
}

#主程序逻辑:处理输入参数
if [[ $# -lt 2 ]]; then
    echo "用法:$0 <文件或目录...> <目标>"
    exit 1
fi

#提取目标
dest="${@: -1}"

#提取最后一个字符
last_char="${dest: -1}"

#判断最后一个字符是否为"/"
if [[ "$last_char" == "/" ]]; then
    if [[ ! -d "${dest}" ]]; then
        mkdir -p "$dest" || {
            echo "创建目标路径失败"
            exit 1
        }
    fi
fi

#遍历所有源文件/目录并进行复制
for item in "${@:1:$#-1}"; do
    copy_item "$item" "$dest"
done
