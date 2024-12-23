#!/usr/bin/env bash

#=text
#@parse csv file

if [ $# -ne 1 ]; then
    echo "用法:$(basename $0) <csv文件路径>"
    exit 1
fi

csv_file=$1

if [ ! -f "$csv_file" ]; then
    echo "错误:文件:$csv_file不存在"
    exit 1
fi

#逐行读取文件
#有表头
first_line=true
while IFS=',' read -r -a fields; do
    if [[ "$first_line" == true ]]; then
        for i in "${!fields[@]}"; do
            echo "title-$((i + 1)):${fields[i]}"
        done
        echo
        first_line=false
        continue
    fi

    for i in "${!fields[@]}"; do
        echo "column-$((i + 1)):${fields[i]}"
    done
    echo
done <"$csv_file"
