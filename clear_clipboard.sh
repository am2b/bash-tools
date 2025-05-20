#!/usr/bin/env bash

#=tools
#@clear pbcopy
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
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    osascript -e 'set the clipboard to ""'
}

main "${@}"
