#!/usr/bin/env bash

#=tools
#@报告当前目录下非隐藏的普通文件,隐藏的普通文件以及总普通文件数量(非递归)
#@usage:
#@script.sh

set -euo pipefail

usage() {
    local script
    script=$(basename "$0")
    cat >&2 << EOF
报告当前目录下普通文件数量:非隐藏、隐藏、合计(非递归)。

用法:
  $script

选项:
  -h    显示此帮助信息
EOF
    exit "${1:-1}"
}

check_parameters() {
    if (("$#" > 0)); then
        echo "error: 不接受额外参数" >&2
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case "$opt" in
            h) usage 0 ;;
            \?)
                echo "error: unsupported option -$OPTARG" >&2
                usage
                ;;
            :)
                echo "error: option -$OPTARG requires an argument" >&2
                usage
                ;;
        esac
    done
}

main() {
    process_opts "$@"
    shift $((OPTIND - 1))
    check_parameters "$@"

    local current_dir
    current_dir=$(pwd)

    local hidden=0 non_hidden=0 total=0
    while IFS= read -r -d $'\0' file; do
        local name
        name=$(basename "$file")
        if [[ "$name" == .* ]]; then
            ((hidden++))
        else
            ((non_hidden++))
        fi
        ((total++))
    done < <(find "$current_dir" -maxdepth 1 -type f -print0)

    #$HOME开头的路径替换为~
    local display_dir="$current_dir"
    if [[ "$current_dir" == "$HOME"* ]]; then
        display_dir="~${current_dir#"$HOME"}"
    fi

    echo "当前目录:$display_dir"
    echo "非隐藏的普通文件数量:$non_hidden"
    echo "隐藏的普通文件数量:$hidden"
    echo "总普通文件数量:$total"
}

main "$@"
