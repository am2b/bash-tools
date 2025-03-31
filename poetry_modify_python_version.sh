#!/usr/bin/env bash

#=python
#@读取.python-version,然后修改pyproject.toml里面的python版本
#@usage:
#@在项目根目录运行
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

    if [[ ! -f .python-version ]]; then
        echo "没有找到.python-version文件"
        exit 1
    fi

    if [[ ! -f pyproject.toml ]]; then
        echo "没有找到pyproject.toml文件"
        exit 1
    fi

    local version
    version=$(cat .python-version)

    sed -E -i "s/(requires-python = \">=)[^\"]*(\")/\1$version\2/" pyproject.toml

    echo "新的版本号:"
    sed -n "/requires-python/p" < pyproject.toml
}

main "${@}"
