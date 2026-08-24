#!/usr/bin/env bash

#=tools
#@在binsplit把多个文件分割完成后,执行该脚本从各个parts子目录里收取manifests文件和所有的文件片段
#@usage:
#@script.sh dir
#@dir:包含多个file1.parts,file2.parts的目录

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir" >&2
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
    REQUIRED_TOOLS=(fd)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    dir="${1}"
    cd "${dir}" || exit 1

    #将manifests都收集到当前目录
    fd --mindepth 2 -e txt . . -X mv {} ./

    #将文件片段都收集到新创建的parts子目录里
    fd --min-depth 2 -t f '^[^.]+$' . -X bash -c 'mkdir -p parts && mv "$@" parts/' bash

    #删除空的目录:file1.parts,file2parts等
    find . -type d -empty -delete
}

main "${@}"
