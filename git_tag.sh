#!/usr/bin/env bash

#=git-tag
#@打标签,并push标签
#@usage: script.sh tag_name

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script tag_name" >&2
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &> /dev/null; then
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
    if (("$#" != 1)); then
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

    if [ -z "$1" ]; then
        echo "Error: Tag name is required."
        echo "Usage: $0 tag_name"
        exit 1
    fi

    local tag_name="${1}"

    # 打标签
    if ! git tag "${tag_name}"; then
        echo "Error: Failed to create tag '${tag_name}'"
        exit 1
    fi

    # 推送标签
    if ! git push origin "${tag_name}"; then
        echo "Error: Failed to push tag '${tag_name}' to remote"
        exit 1
    fi

    echo "Tag '${tag_name}' successfully created and pushed."
}

main "${@}"
