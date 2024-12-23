#!/usr/bin/env bash

#=convenient
#@find aliases for a command
#@usage:
#@script.sh command_name or alias_name

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script command_name or alias_name"
    exit 0
}

while getopts "h" opt; do
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
shift $((OPTIND - 1))

if (( $# != 1 )); then
    usage
fi

#想要查找的command
command="${1}"

alias_path="${DOTS}"/zsh
#查找.aliases开头的文件,找到和给定参数相匹配的行,然后存储数组matched_lines中
mapfile matched_lines < <(fd --hidden .aliases "${alias_path}" | xargs rg --hidden --fixed-strings "${command}")

matched_alias=()
for a in "${matched_lines[@]}"; do
    #在字符串中从左向右查找一个子串,查找到第一个匹配后,删除子串及其左侧的所有字符:
    a="${a#*":"}"
    #删除换行符(-d:delete all occurrences of the specified set of characters from the input)
    a=$(echo "${a}" | tr -d '\n')
    matched_alias+=("${a}")
done

for a in "${matched_alias[@]}"; do
    #'#'开头的行不输出
    echo "${a}" | sed -n '/^#/!p'
done
