#!/usr/bin/env bash

#=tools
#@列出占用CPU最高的几个进程
#@usage:
#@script.sh

#打印的进程数量
num_lines=5

#打印的列的数量
columns_size=4

#打印时每列的宽度
COL_WIDTH=10

#title
columns=("CPU%" "MEM%" "PID" "Process")
#ps命令表示每列的参数
ps_params=("%cpu" "%mem" "pid" "comm")

#每列依次的颜色
color_columns=(
    "\033[31m"
    "\033[32m"
    "\033[33m"
    "\033[34m"
)

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" != 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #title的颜色
    local color_title="\033[1;36m"
    #默认的颜色
    local color_reset="\033[0m"

    if (("${#columns[@]}" != columns_size)); then
        echo "error:title的数量错误"
        exit 1
    fi

    if (("${#ps_params[@]}" != columns_size)); then
        echo "error:ps命令中表示列的数量错误"
        exit 1
    fi

    if (("${#color_columns[@]}" != columns_size)); then
        echo "error:表示每列颜色的数量错误"
        exit 1
    fi

    local ps_args
    ps_args=$(
        IFS=,
        echo "${ps_params[*]}"
    )

    local columns_str
    columns_str="${columns[*]}"

    ps -er -o "$ps_args" | awk -v lines="$num_lines" \
        -v color_title="$color_title" \
        -v color_reset="$color_reset" \
        -v color_cpu="${color_columns[0]}" \
        -v color_mem="${color_columns[1]}" \
        -v color_pid="${color_columns[2]}" \
        -v color_proc="${color_columns[3]}" \
        -v columns_str="$columns_str" \
        -v col_width="$COL_WIDTH" \
        '
    BEGIN {
        split(columns_str, cols, " ")
        fmt = sprintf("%%-%ds", col_width)  # 首列格式
        for (i = 2; i <= length(cols); i++) {
            if (i == length(cols)) {
                fmt = fmt " %s\n"  # 最后一列格式
            } else {
                fmt = fmt sprintf(" %%-%ds", col_width)  # 中间列格式
            }
        }
        printf color_title
        printf fmt, cols[1], cols[2], cols[3], cols[4]  # 打印标题
        printf color_reset
    }
    NR > 1 && NR <= lines+1 {
        split($4, path_arr, "/")
        proc_name = path_arr[length(path_arr)]
        
        cpu_fmt = sprintf("%.1f", $1)
        mem_fmt = sprintf("%.1f", $2)
        pid_fmt = sprintf("%d", $3)
        
        data_fmt = color_cpu "%-" col_width "s" color_reset " " color_mem "%-" col_width "s" color_reset " " color_pid "%-" col_width "s" color_reset " " color_proc "%-" col_width "s" color_reset "\n"

        printf data_fmt, cpu_fmt, mem_fmt, pid_fmt, proc_name
    }
    '
}

main "${@}"
