#!/usr/bin/env bash

#=tools
#@keep only the latest few files and delete the older ones
#@usage:
#@script.sh dir keep_num

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script dir keep_num"
    exit 1
}

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local dir
    dir=$(realpath "${1}")
    local keep_num
    keep_num="${2}"

    #计算文件数量
    counts=$(find "${dir}" -name ".DS_Store" -prune -o -type f -print | wc -l)
    if ((counts > keep_num)); then
        #查找文件并按修改时间排序
        #-name ".DS_Store" -prune:跳过.DS_Store
        #-printf "%T@ %p\0":
        #%T@:文件的修改时间戳(@结尾表示Unix时间戳)
        #%p:文件的完整路径
        #\0(NUL分隔符):防止文件名包含空格,换行,特殊字符时出错
        #sort:
        #-n:按数值(时间戳)升序排序,确保最旧的文件在前
        #-z:处理NUL(\0)分隔符,确保文件名中有空格时不会被拆开
        #head:
        #-n:取前X行,即删除counts - max_num个最旧的文件
        #-z:以NUL分隔符处理,防止文件名中包含换行符或空格时出错
        #cut -d ' ':以空格作为分隔符,切割"时间戳文件路径"
        #-f2-:取第2列及其之后的内容,即文件路径(-f1是时间戳)
        #-z:处理NUL分隔符,防止路径中包含换行或空格时出错
        #IFS=
        #清空IFS(输入字段分隔符),确保read读取整个路径而不拆分
        #read:
        #-r:不转义反斜杠(避免路径\被误解析)
        #-d '':以NUL(\0)作为分隔符,防止文件名包含空格或换行时出错
        find "${dir}" -name ".DS_Store" -prune -o -type f -printf "%T@ %p\0" |
            sort -zn |
            head -z -n "$((counts - keep_num))" |
            cut -z -d ' ' -f2- |
            while IFS= read -r -d '' file; do
                rm -f "${file}"
            done
    fi
}

main "${@}"
