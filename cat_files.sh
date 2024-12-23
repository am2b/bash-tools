#!/usr/bin/env bash

#=tools
#@拼接文本文件
#@usage:
#@script.sh(默认当前目录)
#@script.sh dir
#@script.sh files

#当前一个文本文件最后没有空行的时候,在其后追加1行空行
files=()
output_file="/tmp/output.txt"
append_blank=1

#清空输出文件
>"$output_file"

if (($# == 0)); then
    #获取当前目录下的所有文本文件,按文件名排序
    #当使用管道(|)时,整个管道的命令都会在一个子shell中执行
    #find . -maxdepth 1 -type f -name "*.txt" -print0 | while IFS= read -r -d $'\0' file; do
    #    files+=("${file}")
    #done
    #使用sort -z对null字符分隔的输入进行排序
    mapfile -d $'\0' -t files < <(find . -maxdepth 1 -type f -name "*.txt" -print0 | sort -z)
elif [[ -d "${1}" ]]; then
    mapfile -d $'\0' -t files < <(find "${1}" -maxdepth 1 -type f -name "*.txt" -print0 | sort -z)
else
    #至此,认为参数全部都是文件
    for file in "${@}"; do
        if [[ -f "${file}" ]]; then
            files+=("${file}")
        fi
    done

    while IFS= read -r -d $'\0' file; do
        sorted_files+=("$file")
    done < <(printf '%s\0' "${files[@]}" | sort -z) #通过printf使用null字符(\0)分隔每个文件名
    files=("${sorted_files[@]}")
fi

#拼接文件
for file in "${files[@]}"; do
    #确保文件可读
    if [ ! -r "$file" ]; then
        echo "警告:无法读取文件$file,跳过"
        continue
    fi

    #如果输出文件不为空且最后一行不是空行,则插入空行
    if [ -s "$output_file" ]; then
        last_line=$(tail -n 1 "$output_file")
        if [ -n "$last_line" ]; then
            for ((i = 0; i < append_blank; i++)); do
                echo "" >>"$output_file"
            done
        fi
    fi

    #拼接当前文件的内容
    cat "$file" >>"$output_file"
done

#最终文件的最后一行如果是空行的话,则删除空行
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${output_file}"

echo "文件已成功拼接至:$output_file"
