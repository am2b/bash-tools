#!/usr/bin/env bash

#=tools
#@计算相对于基准日期(默认为当天)的过去/未来日期
#@usage:
#@script.sh [+]/-天数
#@script.sh [+]/-天数 基准日期(YYYY-MM-DD)

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script [+]/-天数" >&2
    echo "$script [+]/-天数 基准日期(YYYY-MM-DD)" >&2
    exit "${1:-1}"
}

check_parameters() {
    if (($# < 1)) || (($# > 2)); then
        usage
    fi
}

is_gnu_command() {
    local cmd="$1"
    local path

    if ! path=$(command -v "$cmd"); then
        echo "Command not found:$cmd" >&2
        return 2
    fi

    if "$path" --version 2>/dev/null | grep -q "GNU"; then
        echo "GNU"
        return 0
    fi

    if command -v strings >/dev/null; then
        if strings "$path" 2>/dev/null | grep -qi "GNU"; then
            echo "GNU"
            return 0
        fi
    fi

    echo "BSD"
    return 1
}

calculate_date() {
    local days=$1
    #默认使用当天
    local base_date=${2:-$(date +%F)}

    #GNU date
    if is_gnu_command date >/dev/null; then
        #-d:指定输入日期字符串
        #+%F:%Y-%m-%d
        date -d "$base_date $days days" +%F
    else
        #macOS BSD
        if ((days >= 0)); then
            #-j:不修改系统时间仅做计算(BSD特有)
            #-v:时间偏移量调整("+105d"表示加105天)
            #-f:指定输入日期格式
            date -j -v "+${days}d" -f "%Y-%m-%d" "$base_date" +%F
        else
            date -j -v "${days}d" -f "%Y-%m-%d" "$base_date" +%F
        fi
    fi
}

main() {
    if [[ $1 == "-h" ]]; then
        usage 0
    fi

    check_parameters "${@}"

    if [[ $1 =~ ^[+-]?[0-9]+$ ]]; then
        calculate_date "$1" "$2"
    else
        echo "错误:天数参数必须为整数(可带+-号)"
        exit 2
    fi
}

main "${@}"
