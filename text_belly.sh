#!/usr/bin/env bash

#=text
#@读取文本文件,然后输出指定的行范围,其中第一个数字表示起始行,第二个数字表示需要显示的行数
#@usage:
#@script.sh text.txt 101 20

if [ "$#" -ne 3 ]; then
    echo "Usage: $(basename "$0") <file> <start_line> <end_line>"
    exit 1
fi

file="$1"
start_line="$2"
line_nums="$3"

if [ ! -f "$file" ]; then
    echo "Error: File '$file' does not exist."
    exit 1
fi

#检查起始行号是否为整数
if ! [[ "$start_line" =~ ^[0-9]+$ ]]; then
    echo "Error: Start lines must be integers."
    exit 1
fi

#检查行数是否为整数
if ! [[ "$line_nums" =~ ^[0-9]+$ ]]; then
    echo "Error: lines number must be integers."
    exit 1
fi

#确保起始行号大于0
if ((start_line <= 0)); then
    echo "Error: Start line must be greater than 0"
    exit 1
fi

# 获取文件总行数
total_lines=$(wc -l <"$file" | tr -d '[:space:]')

# 确保起始行号在文件范围内
if ((start_line > total_lines)); then
    echo "Error: Start line ($start_line) exceeds total lines:($total_lines)."
    exit 1
fi

#如果start_line+line_nums超过文件总行数,调整为总行数
if ((start_line + line_nums > total_lines)); then
    line_nums=$((total_lines - start_line))
fi

#sed无法输出原始的行号
#sed -n "${start_line},+${line_nums}p" "$file"

#awk没有输出原始行号的版本
awk "NR>=${start_line} && NR<${start_line}+${line_nums}" "$file"

#awk输出原始行号的版本
#awk "NR>=${start_line} && NR<${start_line}+${line_nums} {print NR, \$0}" "$file"
