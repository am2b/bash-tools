#!/usr/bin/env bash

#=tools
#@报告当前目录下非隐藏文件,隐藏文件以及总文件数量

# 获取当前目录
current_dir=$(pwd)

# 获取非隐藏文件数量
non_hidden_files=$(find "$current_dir" -maxdepth 1 -type f ! -name ".*" | wc -l | xargs)

# 获取隐藏文件数量
hidden_files=$(find "$current_dir" -maxdepth 1 -type f -name ".*" | wc -l | xargs)

# 获取总文件数量
total_files=$(find "$current_dir" -maxdepth 1 -type f | wc -l | xargs)

# 输出报告
# 如果当前路径是$HOME的子路径,替换为~
if [[ $current_dir == $HOME* ]]; then
    current_dir="~${current_dir#$HOME}"
fi
echo "当前目录:$current_dir"
echo "非隐藏文件数量:$non_hidden_files"
echo "隐藏文件数量:$hidden_files"
echo "总文件数量:$total_files"

#find "$current_dir" -maxdepth 1 -type f
#列出当前目录(不递归子目录)下的所有文件
#-name ".*"
#匹配隐藏文件(以.开头的文件)
#wc -l
#统计文件数量

#wc -l命令默认会在输出的数字前添加一些空格来对齐结果
#wc -l | xargs去除了数字前后的多余空白字符
#xargs的作用是将输入中的字符串重新整理为一行,去掉所有多余空格
