#!/usr/bin/env bash

#=tools
#@compare two dirs
#@usage:
#@script.sh dir1 dir2

dir1=""
dir2=""

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script dir1 dir2"
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

    dir1="${1}"
    dir2="${2}"

    if [[ ! -d "$dir1" ]] || [[ ! -d "$dir2" ]]; then
        echo "both arguments must be directories"
        exit 1
    fi

    #使用diff比较目录内容
    #-q(--brief)表示"简要模式",即只输出文件是否不同,而不显示具体的差异内容
    diff_output=$(diff -qr "$dir1" "$dir2")
    if [[ -z "$diff_output" ]]; then
        #echo "the directories are identical"
        return 0
    else
        echo "**********differences found:**********"
        echo "$diff_output"
        return 1
    fi
}

main "${@}"
