#!/usr/bin/env bash

#=tools
#@计算相对于基准日期(默认为当天)的过去/未来日期
#@usage:
#@script.sh [+]/-天数
#@script.sh [+]/-天数 基准日期(YYYY-MM-DD)

set -euo pipefail

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

is_gnu_date() {
    #-d:能算出正确结果就是GNU,否则就是BSD
    [[ $(date -d "2026-01-01 1 day" +%F 2> /dev/null) == "2026-01-02" ]]
}

calculate_date() {
    local days=$1
    days=${days#+}
    #默认使用当天
    local base_date=${2:-$(date +%F)}

    #GNU date
    if is_gnu_date date > /dev/null; then
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
    check_parameters "${@}"

    if [[ $1 == "-h" || $1 == "--help" ]]; then
        usage 0
    fi

    if [[ $1 =~ ^[+-]?[0-9]+$ ]]; then
        #基准日期格式校验:BSD的-f "%Y-%m-%d" 对非法输入只会报原始错误
        if (($# == 2)) && [[ ! $2 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "错误:基准日期必须为 YYYY-MM-DD 格式" >&2
            exit 2
        fi
        calculate_date "$1" "$2"
    else
        echo "错误:天数参数必须为整数(可带+-号)"
        exit 2
    fi
}

main "${@}"
