#!/usr/bin/env bash

#=git-branch
#@基于本地仓库的某个哈希值,在本地创建一个新的分支并切换到该分支
#@usage:
#@script.sh hash new_branch

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script hash new_branch" >&2
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
    if (("$#" != 2)); then
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
    REQUIRED_TOOLS=(git)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    local hash="$1"
    local new_branch="$2"

    #确保该脚本在一个Git仓库中运行
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "error: not a git repository"
        exit 1
    fi

    #检查new_branch是否已存在
    if git show-ref --verify --quiet "refs/heads/$new_branch"; then
        echo "error: branch '$new_branch' already exists"
        exit 1
    fi

    git checkout -b "${new_branch}" "${hash}"
}

main "${@}"
