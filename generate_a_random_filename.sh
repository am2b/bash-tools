#!/usr/bin/env bash

#=tools
#@生成一个随机的文件名,包含:小写字母,数字,_和-
#@开头的第一个字符仅为字母,最后一个字符仅为字母或数字
#@默认长度为10,也可以通过参数指定
#@usage:
#@script.sh
#@script.sh len

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    echo "$script len"
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
    if (("$#" > 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local length=${1:-10}

    #验证长度参数有效性
    if ((length < 1)); then
        echo "错误:长度必须为大于0的整数" >&2
        exit 1
    fi

    #第一个字符必须是字母
    local first_char
    first_char=$(LC_ALL=C tr -dc 'a-z' </dev/urandom | head -c 1)

    #如果长度为1,仅输出第一个字符
    if [ "$length" -eq 1 ]; then
        echo "$first_char"
        exit 0
    fi

    #最后一个字符不能是_或-
    local last_char
    last_char=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 1)

    #生成剩余字符(可包含字母,数字,_和-)
    rest_chars=$(LC_ALL=C tr -dc 'a-z0-9_-' </dev/urandom | head -c $((length - 2)))

    echo "${first_char}${rest_chars}${last_char}"
}

main "${@}"
