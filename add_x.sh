#!/usr/bin/env bash
set -euo pipefail

#=tools
#@给文件添加所有人可执行权限(chmod a+x)
#@usage:
#@add_x.sh [-h] file1 file2...

usage() {
    local script
    script=$(basename "$0")
    cat >&2 << EOF
给一个或多个文件添加所有人可执行权限 (chmod a+x)。

用法:
  $script [选项] file1 [file2 ...]

选项:
  -h    显示此帮助信息

示例:
  $script build.sh deploy.sh
EOF
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "$@"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error: missing required tool(s): ${missing[*]}" >&2
        exit 1
    fi
}

check_envs() {
    if (("$#" == 0)); then
        return 0
    fi

    for var in "$@"; do
        # 如果变量未导出或值为空
        if [[ -z "${!var:-}" ]]; then
            echo "error: this script needs environment variable '$var' to be set and non-empty" >&2
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
            \?)
                echo "error: unsupported option -$OPTARG" >&2
                usage
                ;;
            :)
                echo "error: option -$OPTARG requires an argument" >&2
                usage
                ;;
            *)
                usage
                ;;
        esac
    done
}

main() {
    local REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"

    local REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1

    process_opts "$@"
    shift $((OPTIND - 1))

    check_parameters "$@"

    local exit_code=0
    for arg; do
        if [[ -d "$arg" ]]; then
            echo "error: '$arg' is a directory, skipped" >&2
            exit_code=1
            continue
        fi

        if [[ ! -e "$arg" ]]; then
            echo "error: '$arg' does not exist, skipped" >&2
            exit_code=1
            continue
        fi

        if [[ ! -f "$arg" ]]; then
            echo "error: '$arg' is not a regular file, skipped" >&2
            exit_code=1
            continue
        fi

        if ! chmod a+x -- "$arg"; then
            echo "error: failed to chmod '$arg'" >&2
            exit_code=1
        fi
    done

    exit "$exit_code"
}

main "$@"
