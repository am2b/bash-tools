#!/usr/bin/env bash

#=tools
#@获取当前app的名字
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

    sleep 2
    osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'
    #say "名字打印出来了"
    printf "\a"
}

main "${@}"
