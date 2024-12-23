#!/usr/bin/env bash

#=tools
#@快速清空参数所给的子目录

if (($# != 1)); then
    echo "usage:$(basename "$0") subdir"
    exit 1
fi

if [[ ! -d "${1}" ]]; then
    echo "${1} is not a directory"
    exit 1
fi

if ! command -v trash &>/dev/null; then
    echo "this script uses the \"trash\" command."
    exit 1
fi

subdir="${1}"

#获取当前日期时间,格式为YYYY-MM-DD_HH-MM-SS
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
tgz_file="$subdir"_"$timestamp".tgz
tar -zcf "${tgz_file}" "${subdir}"

trash "${tgz_file}"

#删除指定目录subdir中的所有内容,包括文件和子目录,但保留subdir本身
find "${subdir}" -mindepth 1 -delete

#find subdir
#表示从目录subdir开始查找
#-mindepth 1
#-mindepth 1的意思是从深度为1的项目开始,忽略深度为0的项目
#深度为0的项目是subdir本身,因此它不会被删除
#-delete
#直接删除find查找到的内容:
#删除文件,空目录和非空目录
#一旦执行,操作不可逆
#注意:-delete必须放在find的参数末尾

#等效于
#rm -rf subdir/*
