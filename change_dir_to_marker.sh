#!/usr/bin/env bash

#=tools
#@cd to marker,which located in ~/.marker_dirs
#@usage:
#@source script.sh marker

usage() {
    echo "usage:"
    echo "source script.sh marker"
    return 1
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

    local param_marker="${1}"
    local cd_to=''

    #读取~/.marker_dirs
    local marker_dirs="${HOME}"/.marker_dirs

    #如果~/.marker_dirs不存在,那么返回
    if ! [ -f "${marker_dirs}" ]; then
        return 0
    fi

    while read -r line; do
        #在字符串中从右向左查找一个子串,查找到最后一个匹配后,删除子串及其右侧的所有字符:
        local find_marker=${line%%","*}
        #在字符串中从左向右查找一个子串,查找到第一个匹配后,删除子串及其左侧的所有字符:
        local find_path=${line#*","}
        #找到和marker所匹配的绝对路径
        if [[ "${find_marker}" == "${param_marker}" ]]; then
            cd_to="${find_path}"
        fi
    done <"${marker_dirs}"

    #如果字符串cd_to的长度不为0
    if [[ -n "${cd_to}" ]]; then
        #把~或者$HOME变量的字符串替换成实际的$HOME值
        cd_to="${cd_to/#\~/$HOME}"
        cd_to="${cd_to/\$HOME/$HOME}"
        if [[ -d "${cd_to}" ]]; then
            cd "${cd_to}"
        else
            return 1
        fi
    else
        #如果没有匹配的marker,那么返回
        return 0
    fi

    eza
}

main "${@}"
