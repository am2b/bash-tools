#!/usr/bin/env bash

#=go
#@在~/repos/go-tools/tools/目录下新建一个工具
#@usage:
#@script.sh tool_name

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script tool_name" >&2
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
}

check_parameters() {
    if (("$#" != 1)); then
        usage
    fi
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

main() {
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local TOOL_NAME="${1}"

    cd ~/repos/go-tools/ || exit 1
    mkdir -p tools/"${TOOL_NAME}"
    cd tools/"${TOOL_NAME}" || exit 1
    go mod init github.com/"${GITHUB_USERNAME}"/go-tools/tools/"${TOOL_NAME}"

    touch main.go
}

main "${@}"
