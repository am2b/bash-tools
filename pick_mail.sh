#!/usr/bin/env bash

#=tools
#@pick a mail address

# 检查是否传入了文件路径
if [ -z "$1" ]; then
    echo "请提供文本文件路径。"
    exit 1
fi

# 从文件中随机选择一行
#shuf -n 1 "$1":随机选择一行
#tr -d '\n':去掉换行符
#pbcopy:命令将内容放到macOS剪贴板
selected_line=$(shuf -n 1 "$1" | tr -d '\n')

# 将选中行放到剪贴板
echo -n "$selected_line" | pbcopy

echo "已复制到剪贴板:"
echo "${selected_line}"
