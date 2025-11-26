#!/usr/bin/env bash

#=text
#@功能:
#@检查my_text_file的每一行,如果某行完全等于参考文件ref_text_file里面的某一行的话,就将其从my_text_file里面移除,并且报告
#@usage:
#@script.sh my_text_file ref_text_file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script my_text_file ref_text_file" >&2
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
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local my_file="${1}"
    local ref_file="${2}"

    #local tmp_file="$(mktemp)"
    #SC2155:
    #分开声明和赋值,以避免掩盖返回值
    #当在一行内同时声明并赋值一个变量(尤其是使用local或declare),并且赋值表达式中包含命令替换($(...)或`...`)时
    #local本身是一个命令,它的返回值会覆盖mktemp命令的返回值,如果你想检查mktemp是否执行成功(比如返回值$?),你会发现无法获取,因为它已经被local的返回值覆盖了,这样你就无法判断命令替换中的mktemp命令是否真的执行成功了
    local tmp_file
    tmp_file="$(mktemp)"

    #载入ref_file里面的行
    declare -A seen
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ -z "${line}" ]] && continue
        seen["${line}"]=1
    done < "${ref_file}"

    echo "从${my_file}中删除的行:"

    local deleted_count=0

    #处理my_file
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ -n "${seen[$line]+yes}" ]]; then
            echo "$line"
            ((deleted_count++))
        else
            echo "$line" >> "$tmp_file"
        fi
    done < "${my_file}"

    #覆盖my_file
    mv "${tmp_file}" "${my_file}"

    echo "总共删除了$deleted_count行"
}

main "${@}"
