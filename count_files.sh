#!/usr/bin/env bash

#=tools
#@报告当前目录下非隐藏文件,隐藏文件以及总文件数量(非递归)
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script" >&2
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
    if (("$#" > 0)); then
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

    # 获取当前目录
    current_dir=$(pwd)

    # 获取非隐藏文件数量
    non_hidden_files=$(find "$current_dir" -maxdepth 1 -type f ! -name ".*" | wc -l | xargs)

    # 获取隐藏文件数量
    hidden_files=$(find "$current_dir" -maxdepth 1 -type f -name ".*" | wc -l | xargs)

    # 获取总文件数量
    total_files=$(find "$current_dir" -maxdepth 1 -type f | wc -l | xargs)

    # 输出报告
    # 如果当前路径是$HOME的子路径,替换为~
    if [[ $current_dir == $HOME* ]]; then
        current_dir="~${current_dir#$HOME}"
    fi
    echo "当前目录:$current_dir"
    echo "非隐藏文件数量:$non_hidden_files"
    echo "隐藏文件数量:$hidden_files"
    echo "总文件数量:$total_files"
}

main "${@}"

#find "$current_dir" -maxdepth 1 -type f
#列出当前目录(不递归子目录)下的所有文件
#-name ".*"
#匹配隐藏文件(以.开头的文件)
#wc -l
#统计文件数量

#wc -l命令默认会在输出的数字前添加一些空格来对齐结果
#wc -l | xargs去除了数字前后的多余空白字符
#xargs的作用是将输入中的字符串重新整理为一行,去掉所有多余空格
