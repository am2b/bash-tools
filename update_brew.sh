#!/usr/bin/env bash

#=tools
#@更新通过homebrew安装的包,不包括cask软件包
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
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
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    brew update

    #仅更新普通包
    echo "----------------------------------------"
    brew upgrade --formula -y --yes

    echo "----------------------------------------"
    brew cleanup
}

main "${@}"
