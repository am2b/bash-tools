#!/usr/bin/env bash

#=tools
#@给文件添加x权限
#@usage:
#@script.sh file1 file2...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file1 file2..." >&2
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

check_envs() {
    if (("$#" == 0)); then
        return 0
    fi

    for var in "$@"; do
        #如果变量未导出或值为空
        if [ -z "$(printenv "$var" 2> /dev/null)" ]; then
            echo "error:this script uses unexported environment variables:${var}"
            return 1
        fi
    done

    return 0
}

check_parameters() {
    if (("$#" == 0)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case "$opt" in
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
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    for arg; do
        if [[ -d "${arg}" ]]; then
            exit 1
        fi

        if [[ ! -f "${arg}" ]]; then
            exit 1
        fi

        chmod a+x -- "${arg}"
    done
}

main "${@}"
