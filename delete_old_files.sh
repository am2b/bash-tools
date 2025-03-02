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

delete_old_files() {
    local dest_dir
    local keep_num
    dest_dir=$(realpath "${1}")
    keep_num="${2}"

    exclude_files_dirs=(".DS_Store" ".git")
    prune_expr=()
    for e in "${exclude_files_dirs[@]}"; do
        prune_expr+=(-name "$e" -prune -o)
    done

    local find_counts
    #递归搜索
    find_counts=$(find "${dest_dir}" \( "${prune_expr[@]}" -false \) -o -type f -print | wc -l)
    if ((find_counts > keep_num)); then
        find "${dest_dir}" \( "${prune_expr[@]}" -false \) -o -type f -printf "%T@ %p\0" |
            sort -zn |
            head -z -n "$((find_counts - keep_num))" |
            cut -z -d ' ' -f2- |
            while IFS= read -r -d '' file_to_be_deleted; do
                trash "${file_to_be_deleted}"
            done
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local tools=("trash")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "error:$tool is not installed"
            exit 1
        fi
    done

    if [[ ! -d "${HOME}"/.trash ]]; then
        echo "error:no trash can found"
        exit 1
    fi

    local dir
    dir="${1}"
    local keep_num
    keep_num="${2}"

    delete_old_files "${dir}" "${keep_num}"
}

main "${@}"

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
