#!/usr/bin/env bash

#=tools
#@copy filenames to general pasteboard
#@usage:script.sh file1.sh file2.py file3.txt ...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script file1.sh file2.py file3.txt ..."
    exit 1
}

check_parameters() {
    if (("$#" == 0)); then
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

    echo -n "$*" | pbcopy
}

main "${@}"
