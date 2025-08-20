#!/usr/bin/env bash

#=tools
#@移动参数目录下的子目录里面的所有文件到参数目录,然后删除空的子目录
#@usage:
#@script.sh dir

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
    REQUIRED_TOOLS=(fd)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local dir="${1}"
    fd . -t f "${dir}" -x bash -c 'f="{}"; base=$(basename "$f"); [ "$f" != "${1}/$base" ] && mv "$f" "${1}/$base"' _ "${dir}"
    #-x bash -c '...':用shell脚本处理每个文件
    #[ "$f" != "${1}/$base" ]:如果文件已经在目标位置就跳过
    #mv "$f" "${1}/$base":移动到根目录
    #其中的${1}就是最后的${dir}

    #删除空的子目录
    find "${dir}" -type d -empty -delete
}

main "${@}"
