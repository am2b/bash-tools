#!/usr/bin/env bash

#=tools
#@tgz a folder but exclude .git and .DS_Store
#@usage:bash script_name.sh /path/to/directory

#检查是否传递了目录路径参数
if [ -z "$1" ]; then
  echo "请提供要打包的目录路径"
  exit 1
fi

#定义目标目录和压缩文件名
TARGET_DIR="$1"
TAR_FILE="${TARGET_DIR%/}.tar.gz"

#使用tar和gzip压缩目录,排除.git和.DS_Store文件
tar --exclude=".git" --exclude=".DS_Store" -czvf "$TAR_FILE" -C "$(dirname "${TARGET_DIR%/}")" "$(basename "${TARGET_DIR%/}")"

echo "打包完成:$TAR_FILE"

#-C "$(dirname "${TARGET_DIR%/}")":
#这是为了确保tar从正确的目录开始(父目录),而不打包完整路径
#tar czvf:c代表创建新的tar文件,z代表通过gzip压缩,v代表详细输出,f代表输出到文件
