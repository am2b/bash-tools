#!/usr/bin/env bash

#=tools
#@zip a folder but exclude .git and .DS_Store
#@usage:bash script_name.sh /path/to/directory

#检查是否传递了目录路径参数
if [ -z "$1" ]; then
  echo "请提供要打包的目录路径"
  exit 1
fi

#定义目标目录和压缩文件名
TARGET_DIR="$1"
ZIP_FILE="${TARGET_DIR%/}.zip"

# 使用zip命令将目录压缩,排除.git和.DS_Store文件
zip -r "$ZIP_FILE" "$TARGET_DIR" -x "*.git/*" "*.DS_Store"

echo "打包完成:$ZIP_FILE"
