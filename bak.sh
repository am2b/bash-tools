#!/usr/bin/env bash

#=tools
#@create a file/dir.bak from file/dir,or create a file/dir from file/dir.bak
#@usage:
#@bak.sh file/dir -> file/dir.bak
#@bak.sh file/dir.bak -> file/dir

set -euo pipefail

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file/dir" >&2
    echo "$script file/dir.bak" >&2
    exit "${1:-1}"
}

check_parameters() {
    if (("$#" != 1)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
            h)
                usage 0
                ;;
            *)
                echo "error:unsupported option -${OPTARG}" >&2
                usage
                ;;
        esac
    done
}

#统一回收:有trash命令用它,没有就退回rm -rf并给出提示
send_to_trash() {
    if command -v trash > /dev/null 2>&1; then
        trash "$@"
    else
        echo "warning:未找到 trash 命令,改用 rm -rf 直接删除:$*" >&2
        rm -rf "$@"
    fi
}

#目标已存在时,先把它移进回收站再拷贝,避免静默覆盖丢旧备份
move_to_trash_if_exists() {
    if [[ -e "$1" || -L "$1" ]]; then
        local TIMESTAMP unique_name n
        TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        unique_name="$1_${TIMESTAMP}"
        n=1
        #唯一名防撞:同秒内已有同名则加:_1 _2 …
        while [[ -e "${unique_name}" ]]; do
            unique_name="$1_${TIMESTAMP}_${n}"
            n=$((n + 1))
        done
        mv "$1" "${unique_name}"
        send_to_trash "${unique_name}"
    fi
}

bak_file() {
    cd "${dir_name}" || exit 1

    move_to_trash_if_exists "${new_name}"

    cp "${base_name}" "${new_name}"
}

bak_dir() {
    cd "${dir_name}" || exit 1

    move_to_trash_if_exists "${new_name}"

    cp -R "${base_name}" "${new_name}"
}

main() {
    check_parameters "${@}"

    #--help要在getopts之前处理:getopts会把--help当成非法选项
    if [[ $1 == "--help" ]]; then
        usage 0
    fi

    process_opts "${@}"
    shift $((OPTIND - 1))

    if [[ ! -e "${1}" ]]; then
        echo "error:${1} 不存在" >&2
        exit 2
    fi

    base_name=$(basename "${1}")
    suffix="${base_name##*.}"

    if [[ "${suffix}" != 'bak' ]]; then
        #add suffix:.bak
        new_name="${base_name}".bak
    else
        #remove suffix:.bak
        new_name="${base_name%.*}"
    fi

    dir_name=$(dirname "${1}")

    if [[ -f "${1}" ]]; then
        bak_file
        exit 0
    fi

    if [[ -d "${1}" ]]; then
        bak_dir
        exit 0
    fi
}

main "${@}"
