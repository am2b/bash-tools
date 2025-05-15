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

calculate_date() {
    local days=$1
    #默认使用当天
    local base_date=${2:-$(date +%F)}

    #GNU date会输出版本信息(退出状态0),BSD date会报错(非0状态)
    #GNU date
    if date --version &>/dev/null; then
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
