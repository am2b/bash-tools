#!/usr/bin/env bash

#=tools
#@计算参数所指定的文件的sha256值,打印并且复制到剪贴板
#@usage:
#@script.sh file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file" >&2
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

    local file="${1}"
    if [[ ! -f "${file}" ]]; then
        echo "错误:${file}不是一个有效的文件"
        exit 1
    fi

    local ret
    ret=$(sha256sum "$file" | awk '{print $1}')

    echo "${ret}" | tee /dev/tty | pbcopy
}

main "${@}"
