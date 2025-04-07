#!/usr/bin/env bash

#=text
#@删除掉文本文件末尾的一行或多行空行
#@usage:
#@script.sh file.txt

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script file.txt"
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
    if (("$#" != 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local file="${1}"

    if [ ! -f "$file" ]; then
        exit 1
    fi

    if file "$file" | grep -q 'text'; then
        #先删除掉空白字符
        #去除每行末尾的空白字符(空格,Tab等)
        #[[:space:]]*:匹配0个或多个空白字符
        sed -i -e 's/[[:space:]]*$//' "${file}"
        #删除文件尾部多余的空行(保留正文后的一个换行)
        #-e :a:定义一个名为a的标签(label),供后面跳转用(ba就是跳转到a)
        #-e '/^\n*$/{$d;N;ba' -e '}':
            #/^\n*$/:匹配"只包含换行符的行"或者"空行",严格来说这里是GNU sed的兼容写法,正常写法常使用/^$/
            #{…}:对匹配到的行执行一系列命令
                #$d:如果是最后一行,就删除它($是sed中"最后一行"的标志)
                #N:把下一行读进来,合并成一行继续处理
                #ba:跳转回:a标签,继续循环
            #这个循环会一直往下合并,处理,直到没有更多空行
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${file}"
    fi
}

main "${@}"
