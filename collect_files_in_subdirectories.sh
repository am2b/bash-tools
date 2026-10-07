#!/usr/bin/env bash

#=tools
#@移动参数目录下的子目录里面的所有文件到参数目录,然后删除空的子目录
#@usage:
#@script.sh dir

set -euo pipefail

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
        if ! command -v "${tool}" &> /dev/null; then
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

    #去掉尾部斜杠:避免${dir}/$base拼出"dir//file"这种路径
    local dir="${1%/}"
    [[ -n "${dir}" ]] || dir="/"
    if [[ ! -d "${dir}" ]]; then
        echo "error:${dir} 不是目录" >&2
        exit 1
    fi

    #只处理子目录里的文件:--min-depth 2排除目标目录自身的文件
    #-H:包含隐藏文件,--no-ignore:忽略.gitignore等忽略规则
    #-0:按NUL分隔输出,配合read -d ''逐行读取,文件名带空格/引号/换行都安全
    #文件路径作为独立参数传给脚本($1),不再拼接进shell代码,杜绝命令注入
    while IFS= read -r -d '' f; do
        base=$(basename "$f")
        dest="${dir}/${base}"
        #同名冲突检查:目标已存在(含符号链接)即报错退出,避免静默覆盖丢数据
        if [[ -e "${dest}" || -L "${dest}" ]]; then
            echo "error:${dest} 已存在,与 ${f} 同名,中止以避免覆盖" >&2
            exit 1
        fi
        mv "${f}" "${dest}"
        echo "moved: ${f} -> ${dest}"
    done < <(fd -H --no-ignore -t f --min-depth 2 -0 . "${dir}")

    #删除空的子目录
    #! -path "${dir}":排除目标目录自身:BSD(macOS)/GNU find都支持-path
    #而-mindepth是GNU扩展,macOS自带的find不支持
    find "${dir}" -type d -empty ! -path "${dir}" -delete
}

main "${@}"
