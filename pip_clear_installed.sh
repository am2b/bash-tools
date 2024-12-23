#!/usr/bin/env bash

#=python
#@uninstall python packages,but do not delete requirements.txt

#如果requirements.txt文件不存在,则退出
if ! [ -f requirements.txt ]; then
    echo 'generate requirements.txt first.'
    exit 1
fi

#获取到.unpip目录下的所有文件名
unpip_dir='.unpip/'
mapfile -t unpip_files < <(fd --exact-depth 1 --hidden --no-ignore --type f .unpip "${unpip_dir}" --exec basename)

#移除.unpip文件的后缀名,仅留下包名字
for f in "${unpip_files[@]}"; do
    . pip_uninstall.sh "${f%.*}"
done
