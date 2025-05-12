#!/usr/bin/env bash

#=pack
#@打包HOME目录下的一些隐藏文件
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script" >&2
    exit "${1:-1}"
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage 0
            ;;
        *)
            echo "error:unsupported option -$opt" >&2
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" != 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #保存的位置
    local save_dir="${HOME}/save_home_dots"
    mkdir -p "${save_dir}"
    #如果目录非空,则清空
    if [[ -n "$(find "$save_dir" -mindepth 1 -print -quit)" ]]; then
        find "$save_dir" -mindepth 1 -exec rm -rf {} +
    fi

    #要保存的目录和文件
    local -a dirs=(.am2b .config .gnupg .key-ring .local .private .tag .tube-top)
    local -a files=(.bashrc .msmtprc .password .one_key_move)

    #进入~
    cd ~ || exit 1

    #打包
    local pack_name

    #分别打包每个目录
    for dir in "${dirs[@]}"; do
        pack_name="${dir#.}.tar.gz"
        #排除socket和.lock文件
        #--null:告诉tar以null字符分隔读取文件名
        #--no-recursion:禁用默认递归
        #-T -:告诉tar从标准输入读取文件列表
        find "${dir}" ! -type s ! -name '*.lock' -print0 | tar --null -czf "${pack_name}" --no-recursion -T -
        mv "${pack_name}" "${save_dir}"
    done

    #整体打包所有的文件
    pack_name=files.tar.gz
    tar -czf "${pack_name}" "${files[@]}"
    mv "${pack_name}" "${save_dir}"

    echo "已打包备份至:${save_dir}"
}

main "${@}"
