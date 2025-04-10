#!/usr/bin/env bash

#=tools
#@在命令行测试,是否可以连接到google
#@usage:
#@script.sh

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
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    curl -w "总消耗时间:%{time_total}秒\n" -o /dev/null -s https://google.com
}

main "${@}"

#-w "总消耗时间:%{time_total}\n"
#-w 选项指定了curl在请求完成后输出的格式,%{time_total}是一个占位符,表示整个请求过程的总耗时(包括建立连接,发送请求,等待响应,接收响应的所有时间)
#-s 代表--silent,即静默模式,这个选项会关闭curl的进度条和错误信息输出

#time_total 这个变量来自于curl的-w(或--write-out)选项,它允许你指定一个格式化字符串来输出请求的各种信息,curl预定义了一些占位符来表示与请求相关的不同时间参数,包括:
#%{time_total}:总的请求时间(从发送请求到接收到响应的全部过程,单位:秒)
#%{time_connect}:建立连接的时间
#%{time_starttransfer}:从开始请求到接收到响应数据的第一个字节的时间
#%{time_pretransfer}:从开始请求到准备传输数据的时间
#这些占位符都是由curl提供的,在执行命令时会自动替换成实际的数值
