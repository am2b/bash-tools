#!/usr/bin/env bash

#=tools
#@更新通过homebrew安装的包,包括Cask软件包
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

    #更新普通包
    echo "----------------------------------------"
    brew upgrade

    #更新Cask软件包
    #管道符|仅捕获stdout内容
    outdated_casks=$(brew outdated --cask --verbose | awk '{print $1}')
    if [[ -n "${outdated_casks}" ]]; then
        echo "----------------------------------------"
        for app in ${outdated_casks}; do
            brew upgrade --cask "${app}"
        done
    fi

    brew cleanup
}

main "${@}"
