#!/usr/bin/env bash

#=pack
#@把pack_videos.sh和unpack_videos.sh这两个脚本连接起来
#@usage:
#@script.sh dir
#@run_in_background script.sh dir

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir" >&2
    echo "run_in_background $script dir" >&2
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
    if (("$#" != 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #log目录
    mkdir -p /tmp/videos

    #存储数据的目录
    local pack_videos_data_dir
    local storage_file
    pack_videos_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pack_videos"
    storage_file="${pack_videos_data_dir}/storage"

    #打包该目录下的文件
    local dir
    dir="${1}"

    #执行打包
    #2>&1:表示把文件描述符2(标准错误)重定向到1(标准输出)
    pack_videos.sh "${dir}" >/tmp/videos/pack.log 2>&1

    #执行解包并验证
    #读取存储打包文件的目录的绝对路径
    dir=$(<"${storage_file}")
    unpack_videos.sh "${dir}" >/tmp/videos/unpack.log 2>&1
}

main "${@}"
