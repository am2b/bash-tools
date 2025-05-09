#!/usr/bin/env bash

#=tools
#@smart cp

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script <文件或目录...> <目标>"
    exit 1
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

check_parameters() {
    if (("$#" < 2)); then
        usage
    fi
}

#复制文件或目录,并保留原有属性
copy_item() {
    local item="$1"
    local dest="$2"

    if [[ -f "$item" ]]; then
        cp -p "$item" "$dest" || {
            echo "复制文件 '$item' 失败"
            exit 1
        }
    elif [[ -d "$item" ]]; then
        cp -rp "$item" "$dest" || {
            echo "复制目录 '$item' 失败"
            exit 1
        }
    else
        echo "警告:'$item' 既不是文件也不是目录,跳过..."
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #如果source_count大于1,那么就说明最后一个参数肯定是是一个目录
    #注意:计算的时候留空格,这是bash原生整数计算方式(可以避免子shell)
    source_count=$(( $# - 1 ))

    #提取目标
    dest="${@: -1}"

    #提取最后一个字符
    last_char="${dest: -1}"

    #判断最后一个字符是否为"/"
    if [[ "$last_char" == "/" ]] || (( "${source_count}" > 1 )); then
        if [[ ! -d "${dest}" ]]; then
            mkdir -p "$dest" || {
                echo "创建目标路径失败"
                exit 1
            }
        fi
    fi

    #遍历所有源文件/目录并进行复制
    for item in "${@:1:$#-1}"; do
        copy_item "$item" "$dest"
    done
}

main "${@}"
