#!/usr/bin/env bash

#=tools
#@将汉字转换为拼音,或拼音的首字母
#@usage:
#@转换为拼音:
#@script.sh 汉字
#@转换为拼音的首字母:
#@script.sh -f 汉字

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "转换为拼音:"
    echo "$script 汉字"
    echo "转换为拼音的首字母:"
    echo "$script -f 汉字"
    exit 1
}

process_opts() {
    while getopts ":hf" opt; do
        case $opt in
        h)
            usage
            ;;
        f)
            FIRST_LETTER_FLAG=true
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" == 0 || "$#" > 2)); then
        usage
    fi
}

main() {
    check_parameters "${@}"

    process_opts "${@}"

    shift $((OPTIND - 1))

    if ! command -v msmtp &> /dev/null; then
        echo "pypinyin没有安装..."
        echo "pipx install pypinyin"
        exit 1
    fi

    if [[ "${FIRST_LETTER_FLAG}" == true ]]; then
        pypinyin -s FIRST_LETTER "${1}"
    else
        pypinyin -s NORMAL "${1}"
    fi
}

main "${@}"
