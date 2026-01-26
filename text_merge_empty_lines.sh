#!/usr/bin/env bash

#=text
#@合并连续的空行,参数可以是一个/多个文件,一个/多个目录,或者文件与目录
#@usage:
#@script.sh file[s]
#@script.sh dir[s]
#@script.sh file[s] dir[s]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file[s]" >&2
    echo "$script dir[s]" >&2
    echo "$script file[s] dir[s]" >&2
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

merge_empty_lines() {
    local file="$1"

    #跳过符号链接,非文件,二进制文件
    if [[ ! -f "$file" ]] || [[ -L "$file" ]]; then
        echo "跳过:$file(非普通文件或符号链接)"
        return
    fi
    if file --mime-type "$file" | grep -q -v 'text/'; then
        echo "跳过:$file(非文本文件)"
        return
    fi

    #GNU sed合并连续空行
    if ! sed -i '/^$/ { N; /^\n$/ D; }' "$file"; then
        echo "错误:处理 $file 失败(权限不足/文件损坏)"
        return 1
    fi
    echo "处理完成:$file"
}

#递归处理目录下的文本文件
process_directory() {
    local dir="$1"

    if [[ ! -d "$dir" ]] || [[ -L "$dir" ]]; then
        echo "跳过:$dir(非普通目录或符号链接)"
        return
    fi

    #仅遍历普通文本文件(排除符号链接,二进制)
    find "$dir" -type f -not -type l -print0 | while IFS= read -r -d $'\0' file; do
        merge_empty_lines "$file"
    done
}

main() {
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #无参数时提示用法
    if [[ $# -eq 0 ]]; then usage; fi

    for arg in "$@"; do
        if [[ -d "$arg" ]]; then
            process_directory "$arg"
        elif [[ -f "$arg" ]]; then
            merge_empty_lines "$arg"
        else
            echo "跳过:$arg(不是有效的文件/目录)"
        fi
    done

}

main "${@}"
