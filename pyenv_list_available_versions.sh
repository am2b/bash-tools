#!/usr/bin/env bash

#=python
#@列出可以通过pyenv安装的python版本
#@会对版本号进行筛选,可以接收用户输入的目标版本号,默认为3.10.0
#@usage
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

    # 只列出该版本号以后的
    # 可以接收用户输入的目标版本号,默认为3.10.0
    TARGET_VERSION=${1:-3.10.0}

    # 提取主版本、次版本和补丁版本
    MAJOR_VERSION=$(echo "$TARGET_VERSION" | cut -d. -f1)
    MINOR_VERSION=$(echo "$TARGET_VERSION" | cut -d. -f2)
    PATCH_VERSION=$(echo "$TARGET_VERSION" | cut -d. -f3)

    # 筛选版本
    pyenv install --list | awk -v major="$MAJOR_VERSION" -v minor="$MINOR_VERSION" -v patch="$PATCH_VERSION" '
        {
            gsub(/^[ \t]+/, "", $0);
            if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {
                split($1, version, ".");
                if (version[1] == major) {
                    if (version[2] > minor || (version[2] == minor && version[3] >= patch)) {
                        print $1;
                    }
                } else if (version[1] > major) {
                    print $1;
                }
            }
        }
        '
}

main "${@}"

#以下是对命令及其核心逻辑的详细讲解:
#目的:
#从pyenv install --list的输出中,筛选出符合条件的Python版本号(大于或等于指定版本major.minor.patch)

#分解逐步讲解:
#1.管道操作
#pyenv install --list
#输出:列出所有可安装的Python版本,包含普通版本,开发版本以及其他实现(例如pypy)
#数据格式:输出的每一行可能包含:
#2.7.18
#3.6.15
#3.10.0
#3.11.0
#anaconda3-2023.03
#pypy3.9-7.3.11

#2.awk的调用
#awk -v major="$MAJOR_VERSION" -v minor="$MINOR_VERSION" -v patch="$PATCH_VERSION" '...'
#awk是一个强大的文本处理工具
#-v:用于向awk传递外部变量
#major="$MAJOR_VERSION":主版本号,例如3
#minor="$MINOR_VERSION":次版本号,例如10
#patch="$PATCH_VERSION":补丁版本号,例如0

#3.gsub(/^[ \t]+/, "", $0);
#gsub是awk的全局替换函数
#/^[ \t]+/:正则表达式,匹配行首的所有空格和制表符
#"":将匹配内容替换为空,即去除前导空格
#$0:表示当前行的整个内容
#作用:清理行首空格,使版本号的比较更简洁

#4.正则表达式匹配行
#if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) {
#$1:表示当前行的第一个字段(在默认情况下,字段以空格分隔)
#~:表示匹配操作
#/^[0-9]+\.[0-9]+\.[0-9]+$/:正则表达式,用于匹配标准的版本号格式,例如3.10.0
#^[0-9]+:以一到多个数字开头
#\.:匹配点号(.)
#[0-9]+:匹配一个数字片段(例如10)
#$:行尾结束符,确保匹配整行
#作用:过滤掉非版本号的行,例如anaconda3-2023.03和pypy3.9-7.3.11

#5.split函数
#split($1, version, ".");
#split:awk中的字符串分割函数
#$1:当前行第一个字段(已确认是版本号)
#version:将分割后的片段存储到数组version中
#".":指定分隔符为点号'.'
#作用:将版本号3.10.0分割成:
#version[1] = 3
#version[2] = 10
#version[3] = 0

#6.主版本号比较
#if (version[1] == major) {
#比较主版本号是否等于目标主版本号major(例如,3)
#如果主版本号相同,则继续比较次版本号和补丁版本号

#7.次版本号和补丁版本号比较
#if (version[2] > minor || (version[2] == minor && version[3] >= patch)) {
#    print $1;
#}
#version[2] > minor:如果次版本号大于目标次版本号,则符合条件
#(version[2] == minor && version[3] >= patch):
#如果次版本号等于目标次版本号,则比较补丁版本号
#如果补丁版本号大于或等于目标补丁版本号,则符合条件
#print $1:输出满足条件的版本号

#8.主版本号大于目标主版本号
#} else if (version[1] > major) {
#    print $1;
#}
#如果主版本号大于目标主版本号,则直接输出,因为较新的主版本号无需进一步比较

#综合逻辑流程图:
#1.逐行处理pyenv install --list的输出
#2.清除每行的前导空格
#3.筛选标准格式的版本号
#4.将版本号分割为主版本,次版本和补丁版本
#5.依次比较:
#如果主版本号较新,直接输出
#如果主版本号相同:
#比较次版本号
#如果次版本号相同,则比较补丁版本号
#6.输出符合条件的版本号
