#!/usr/bin/env bash

#=tools
#@fuzzy find a bash script,and copy the script name to clipboard
#@usage:
#@fuzzy_find_bash_tools.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
}

check_parameters() {
    if (("$#" != 0)); then
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

    SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    selected_script=$(find "${SELF_ABS_DIR}" -type f | fzf)

    if [[ -n "$selected_script" ]]; then
        selected_script=$(basename "${selected_script}")
        echo -n "${selected_script}" | pbcopy
    else
        exit 0
    fi
}

main "${@}"
