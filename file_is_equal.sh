#!/usr/bin/env bash

#=tools
#@通过计算两个文件的sha256来判断两个文件是否相同

# 检查参数数量
if [ "$#" -ne 2 ]; then
  echo "用法: $0 <文件1> <文件2>"
  exit 1
fi

# 获取文件路径
file1="$1"
file2="$2"

# 检查文件是否存在
if [ ! -f "$file1" ]; then
  echo "错误: 文件 '$file1' 不存在！"
  exit 1
fi

if [ ! -f "$file2" ]; then
  echo "错误: 文件 '$file2' 不存在！"
  exit 1
fi

# 计算文件的 SHA-256 哈希值
hash1=$(sha256sum "$file1" | awk '{print $1}')
hash2=$(sha256sum "$file2" | awk '{print $1}')

# 比较哈希值
if [ "$hash1" == "$hash2" ]; then
  echo "文件 '$file1' 和 '$file2' 相同。"
else
  echo "文件 '$file1' 和 '$file2' 不同。"
fi
