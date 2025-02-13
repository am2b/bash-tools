#!/usr/bin/env bash

#=go
#@go mod init
#@usage:
#@-l:local
#@cd project_root_dir && script.sh [-l]

local_flage=false

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "cd project_root_dir && $script [-l]"
    exit 1
}

check_parameters() {
    if (("$#" > 1)); then
        usage
    fi
}

process_opts() {
    while getopts ":hl" opt; do
        case $opt in
        h)
            usage
            ;;
        l)
            local_flage=true
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

    local project_root_dir
    project_root_dir=$(basename "$(pwd)")

    if [[ "${local_flage}" == false ]]; then
        go mod init "github.com/${GITHUB_USERNAME}/${project_root_dir}"
    else
        go mod init "${project_root_dir}"
    fi
}

main "${@}"
