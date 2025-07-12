#!/usr/bin/env bash

#=git-revert
#@反转指定提交的更改(适用于本地和远程)
#@当提交已经被push到远程仓库后,又不想要某个提交了
#@usage:
#@script.sh HEAD(撤销刚才的提交)
#@script.sh commit/HEAD~2(上上次提交)
#@如果存在冲突,那么解决完冲突后:git revert --continue
#@如果中途要放弃:git revert --abort

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script <commit>" >&2
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

    local commit="${1}"
    git revert "${commit}"
}

main "${@}"
