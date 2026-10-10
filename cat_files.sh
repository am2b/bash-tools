#!/usr/bin/env bash

#=tools
#@拼接文本文件
#@usage:
#@script.sh(默认当前目录)
#@script.sh [-o output] [dir | file1 file2 ...]

set -euo pipefail
IFS=$'\n\t'

# ---------- 全局状态(由parse_args填充) ----------
output_file="/tmp/output.txt"
files=()

# ---------- 帮助信息 ----------
usage() {
    local script
    script=$(basename "$0")
    cat >&2 << EOF
拼接文本文件,按文件名排序后合并。

用法:
  $script [选项] [目录 | 文件...]

无参数时拼接当前目录下的 .txt 文件。

选项:
  -o FILE  指定输出文件 (默认 /tmp/output.txt)
  -h       显示此帮助信息

示例:
  $script
  $script ~/docs
  $script a.txt b.txt c.txt
  $script -o result.txt *.txt
EOF
    exit "${1:-1}"
}

# ---------- 解析命令行参数 ----------
parse_args() {
    while getopts ":ho:" opt; do
        case "$opt" in
            h) usage 0 ;;
            o) output_file="$OPTARG" ;;
            \?)
                echo "错误: 未知选项 -$OPTARG" >&2
                usage 1
                ;;
            :)
                echo "错误: 选项 -$OPTARG 需要参数" >&2
                usage 1
                ;;
        esac
    done
    shift $((OPTIND - 1))
    REMAINING_ARGS=("$@")
}

# ---------- 从目录收集.txt文件 ----------
collect_from_dir() {
    local dir="$1"
    while IFS= read -r -d $'\0' file; do
        files+=("$file")
    done < <(find "$dir" -maxdepth 1 -type f -name "*.txt" -print0 | sort -z)
}

# ---------- 从命令行参数收集文件 ----------
collect_from_args() {
    for file in "$@"; do
        if [[ ! -e "$file" ]]; then
            echo "警告: '$file' 不存在,跳过" >&2
            continue
        fi
        if [[ ! -f "$file" ]]; then
            echo "警告: '$file' 不是普通文件,跳过" >&2
            continue
        fi
        files+=("$file")
    done
}

# ---------- 对文件列表排序(用户手动传参时用) ----------
sort_files() {
    ((${#files[@]} > 0)) || return 0
    local sorted=()
    while IFS= read -r -d $'\0' file; do
        sorted+=("$file")
    done < <(printf '%s\0' "${files[@]}" | sort -z)
    files=("${sorted[@]}")
}

# ---------- 根据参数决定收集策略 ----------
gather_files() {
    if ((${#REMAINING_ARGS[@]} == 0)); then
        collect_from_dir "."
    elif ((${#REMAINING_ARGS[@]} == 1)) && [[ -d "${REMAINING_ARGS[0]}" ]]; then
        collect_from_dir "${REMAINING_ARGS[0]}"
    else
        collect_from_args "${REMAINING_ARGS[@]}"
        sort_files
    fi
}

# ---------- 判断是否为GNU sed ----------
is_gnu_sed() {
    sed --version 2> /dev/null | grep -q GNU
}

# ---------- 删除行尾\r ----------
clean_crlf() {
    local file="$1"
    if is_gnu_sed; then
        sed -i 's/\r$//' "$file"
    else
        sed -i '' 's/\r$//' "$file"
    fi
}

# ---------- 删除文件末尾所有空行 ----------
strip_trailing_blank_lines() {
    local file="$1"
    awk '{ lines[NR] = $0 }
          END {
              last = NR
              while (last > 0 && lines[last] == "") last--
              for (i = 1; i <= last; i++) print lines[i]
          }' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
}

# ---------- 拼接主逻辑 ----------
concatenate() {
    #清空输出文件
    : > "$output_file"

    for file in "${files[@]}"; do
        if [[ ! -r "$file" ]]; then
            echo "警告: 无法读取 '$file',跳过" >&2
            continue
        fi

        # 上一个文件末尾没空行的话,插一个空行做分隔
        if [[ -s "$output_file" ]]; then
            local last_line
            last_line=$(tail -n 1 "$output_file")
            [[ -n "$last_line" ]] && echo "" >> "$output_file"
        fi

        cat -- "$file" >> "$output_file"
    done
}

# ---------- 主入口 ----------
main() {
    parse_args "$@"
    gather_files

    if ((${#files[@]} == 0)); then
        echo "错误: 没有找到任何可拼接的文件" >&2
        exit 1
    fi

    concatenate
    clean_crlf "$output_file"
    strip_trailing_blank_lines "$output_file"

    echo "完成: ${#files[@]} 个文件已拼接至 $output_file"
}

main "$@"
