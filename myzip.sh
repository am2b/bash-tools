#!/usr/bin/env bash

#=pack
#@对zip打包操作的一个包装
#@注意:没有解包功能,解包命令:unzip pack.zip或者x pack.zip
#@usage:
#@script.sh files... dirs...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script files or dirs" >&2
    #${parameter:-word}:这是一种参数扩展机制,要是参数(像$1)没有被设置,或者其值为空字符串,就会用word(这里是1)来替代
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
    if (("$#" == 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #执行脚本时命令行的路径
    local cmd_line_dir
    cmd_line_dir=$(pwd)

    #确保所有的参数都在同一个目录下
    local first_dir
    first_dir=$(dirname "$(realpath "$1")")

    #遍历所有参数并比较其目录
    for path in "$@"; do
        if [ ! -e "$path" ]; then
            echo "错误:'$path'不存在"
            exit 1
        fi

        local dir
        dir=$(dirname "$(realpath "$path")")
        if [ "$dir" != "$first_dir" ]; then
            echo "参数不在同一目录下"
            exit 1
        fi
    done

    #决定包的名字
    local pack_name
    if (($# > 1)); then
        pack_name=$(basename "$first_dir")
    else
        if [[ -d "${1}" ]]; then
            pack_name=$(basename "$1")
        else
            local base_name
            base_name=$(basename "$1")
            #移除后缀名
            pack_name="${base_name%.*}"
        fi
    fi
    pack_name="${pack_name}.zip"

    #进入目录
    cd "${first_dir}" || exit 1

    #收集参数的basename
    local -a basenames=()
    for path in "$@"; do
        basenames+=("$(basename "$path")")
    done

    echo "正在打包:${pack_name}"
    #这里不能直接用$@,而应该用其basename
    #-r:递归,-0:无压缩,-x:排除模式
    #-r:只对目录有意义,它表示"递归地进入子目录打包其中内容",如果目标是一个普通文件,zip会直接打包它,不管是否加了-r
    zip -r -0 "${pack_name}" "${basenames[@]}" -x '*.DS_Store' -x '*.git/*'

    #脚本内部的路径
    local script_current_dir
    script_current_dir=$(pwd)

    #移动包到执行脚本时命令行的路径
    if [[ "${script_current_dir}" != "${cmd_line_dir}" ]]; then
        mv "${pack_name}" "${cmd_line_dir}"
    fi
}

main "${@}"
