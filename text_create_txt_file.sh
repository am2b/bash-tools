#!/usr/bin/env bash

#=text
#@create txt file
#@usage:
#@script.sh path

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script path"
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

    if [[ -z "${1}" ]]; then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local target_dir="$1"
    if [[ ! -d "${target_dir}" ]]; then
        echo "${target_dir}:is not a valid directory"
        exit 1
    fi

    local base_name="新建文本文件"
    local counter=0

    #生成唯一文件名
    while :; do
        if [ $counter -eq 0 ]; then
            filename="${base_name}.txt"
        else
            filename="${base_name}${counter}.txt"
        fi

        #检查文件是否已存在
        if [ ! -f "${target_dir%/}/${filename}" ]; then
            break
        fi
        ((counter++))
    done

    touch "${target_dir%/}/${filename}"
}

main "${@}"
