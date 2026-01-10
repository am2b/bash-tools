#!/usr/bin/env bash

#=tools
#@计算给定目录下文件的数量,包含隐藏文件
#@可以指定后缀名,关键字
#@可以指定忽略项(用逗号分割,逗号两边不能有空格)
#@支持递归
#@usage:
#@script.sh -h

usage() {
    cat << EOF
用法:
$(basename "${0}") [-d <目标目录>] [-e <后缀名>] [-k <关键字>] [-r] [-i <忽略文件,忽略子目录,忽略pattern,...>]

选项:
    -d       指定目标目录(默认为当前目录)
    -e       指定文件后缀名,例如:".txt" 或 "txt"
    -k       指定文件名关键字
    -r       启用递归
    -i       忽略项,使用逗号分隔
    -h       显示此帮助信息

示例:
    $(basename "${0}") -d . -e .go -i vendor,node_modules
    $(basename "${0}") -d /tmp -k log -r
    $(basename "${0}") -k test -e .go
EOF
    exit "${1:-1}"
}

process_opts() {
    while getopts "d:e:k:ri:h" opt; do
        case "$opt" in
            d|e|k|r|i) ;;
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
    process_opts "${@}"

    #tr -d ' ' 的作用是去掉wc -l输出中可能出现的前导空格,保证结果是一个干净,可预测的整数值
    find_files_in_a_dir.sh "${@}" | wc -l | tr -d ' '
}

main "${@}"
