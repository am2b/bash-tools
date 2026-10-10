#!/usr/bin/env bash

#=tools
#@通过计算两个文件的sha256来判断两个文件是否相同
#@usage:
#@file_is_equal.sh file1 file2

set -euo pipefail

usage() {
    echo "用法: $(basename "$0") <文件1> <文件2>" >&2
    echo "  退出码 0 = 相同, 1 = 不同, 其他 = 错误" >&2
    exit "${1:-1}"
}

#Linux用sha256sum,macOS用shasum -a 256
sha256() {
    if command -v sha256sum &> /dev/null; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo "error: 找不到 sha256sum 或 shasum 命令" >&2
        exit 1
    fi
}

main() {
    while getopts ":h" opt; do
        case "$opt" in
            h) usage 0 ;;
            \?)
                echo "error: 未知选项 -$OPTARG" >&2
                usage 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if (($# != 2)); then
        usage 1
    fi

    local file1="$1" file2="$2"

    for f in "$file1" "$file2"; do
        if [[ ! -f "$f" ]]; then
            echo "error: 文件 '$f' 不存在或不是普通文件" >&2
            exit 1
        fi
        if [[ ! -r "$f" ]]; then
            echo "error: 文件 '$f' 不可读" >&2
            exit 1
        fi
    done

    local hash1 hash2
    hash1=$(sha256 "$file1")
    hash2=$(sha256 "$file2")

    if [[ "$hash1" == "$hash2" ]]; then
        echo "文件 '$file1' 和 '$file2' 相同。"
        exit 0
    else
        echo "文件 '$file1' 和 '$file2' 不同。"
        echo "  $file1: $hash1" >&2
        echo "  $file2: $hash2" >&2
        exit 1
    fi
}

main "$@"
