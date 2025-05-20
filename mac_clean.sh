#!/usr/bin/env bash

#=tools
#@清理mac的系统数据
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

    #~/Library/Caches/tealdeer
    #rm -rf "$HOME/Library/Caches/*"

    local PASTEBOARD_ARCHIVES_DIR="$HOME/Library/Group Containers/group.com.apple.coreservices.useractivityd/shared-pasteboard/archives"

    cd "${PASTEBOARD_ARCHIVES_DIR}" || { echo "error:cd ${PASTEBOARD_ARCHIVES_DIR} failed"; exit 1; }
    rm -rf ./*
}

main "${@}"
