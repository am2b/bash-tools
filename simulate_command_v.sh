#!/usr/bin/env bash

#=tools
#@like command+v(or ctrl+v)(with -x option will move) for files and dirs

#0:false
move_flag=0
if (( $# == 1 )) && [[ "${1}" = '-x' ]]; then move_flag=1; fi

record_file=/tmp/simulate_command_c.txt

#如果记录文件不存在的话,就退出
#-r:存在并且可读
if ! [ -r "${record_file}" ]; then exit 1; fi

#用于存储被跳过的文件或目录
skipped=()

#遍历记录文件
while read -r line; do
    #如果不存在的话
    if ! [ -e "${line}" ]; then
        echo 'error:'"${line}"' does not exist!'
        exit 1
    fi

    #如果存在覆盖的风险的话,则跳过
    base_name=$(basename "${line}")
    if [ -e "${base_name}" ]; then
        skipped+=("${line}")
        continue
    fi

    #执行复制操作
    if (( "${move_flag}" == 0 )); then
        if [ -f "${line}" ]; then
            cp "${line}" .
        elif [ -d "${line}" ]; then
            cp -R "${line}" .
        fi
    #执行移动操作
    else
        mv "${line}" .
    fi
done < "${record_file}"

#如果执行了移动操作，那么删除记录文件
if (( "${move_flag}" == 1 )); then
    rm "${record_file}"
fi

#遍历被跳过的数组
for s in "${skipped[@]}"; do
    echo -n 'skipped:'
    echo "${s}"
done
