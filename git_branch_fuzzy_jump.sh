#!/usr/bin/env bash

#=git-branch
#@模糊跳转到某个分支

help_info() {
    local script
    script=$(basename "$0")

    echo "usage:"
    echo "$script branch"
}

#用于标记每个待选项的标签(最多标记10个选项)
array_tags=('\uf0e7' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i')
tags_size="${#array_tags[@]}"

pattern=""

#获取所有分支列表(不包括当前分支)
function get_branches() {
    branches=($(git branch | grep -v '^\*' | sed 's/^ *//'))
    echo "${branches[@]}"
}

#计算匹配得分函数,算法:Longest Common Subsequence(LCS)
function calculate_score() {
    local input="$1"
    local candidate="$2"
    local input_len=${#input}
    local score=0
    local pos=0

    #完美匹配优先,赋予最高分值
    if [[ "$input" == "$candidate" ]]; then
        #返回一个非常高的分值
        echo 1000
        return
    fi

    #模糊匹配得分计算
    for ((i = 0; i < input_len; i++)); do
        char="${input:i:1}"
        pos=$(echo "$candidate" | grep -o -b "$char" | awk -F: '{print $1}' | head -n 1)
        if [[ -n "$pos" ]]; then
            #位置越靠前,得分越高
            score=$((score + 10 - pos))
            #截断匹配后的部分
            candidate=${candidate:pos+1}
        else
            #不匹配得分为0
            echo 0
            return
        fi
    done
    echo "$score"
}

function do_match() {
    local branches
    branches=$(get_branches)

    #计算每个候选项的得分
    declare -A scores
    #这里不能加双引号
    for item in ${branches[@]}; do
        scores["$item"]=$(calculate_score "$pattern" "$item")
    done

    #按得分排序并存储到数组
    local matched_sorted_branches=()
    while IFS= read -r line; do
        matched_sorted_branches+=("$line")
    done < <(for key in "${!scores[@]}"; do
        echo "$key ${scores[$key]}"
    done | sort -k2 -nr | awk '{print $1}')

    echo "${matched_sorted_branches[@]}"
}

#打印匹配的项目
#参数:已经匹配的数组
function print_matched_path() {
    echo 'Press Enter to checkout the first branch'

    #已经匹配的数组
    local array_matched=()
    array_matched=("${@}")

    local right_arrow='\uf061'

    #同时遍历匹配的数组和标签数组,这两个数组的大小不同,所以按照小的数组来遍历
    local matched_size="${#array_matched[@]}"
    local min=$((tags_size < matched_size ? tags_size : matched_size))
    for ((i = 0; i < "${min}"; ++i)); do
        echo -e -n '['"${array_tags[*]:$i:1}"']' ' '
        echo -e -n "${right_arrow}${right_arrow}${right_arrow}" ' '
        echo "${array_matched[*]:$i:1}"
    done

    local num_not_printed
    num_not_printed=$(("${matched_size}" - "${tags_size}"))
    if (("${num_not_printed}" > 0)); then
        echo "There are ${num_not_printed} branches that have not been printed"
    fi

    echo 'Press q to quit.'
}

#读取键盘输入(读取的是用户对a,b,c等的输入)
function read_keyboard() {
    #读取键盘
    local key
    read -r -n 1 key

    echo "${key}"
}

#处理键盘输入
#返回一个索引,该索引值表示array_tags里面的index,也表示了"匹配数组中的目录index"
#返回index为-1就表示直接退出
function process_key() {
    local key
    key=$1

    case "$key" in
    #按下q键退出
    'q' | 'Q')
        echo -1
        return 0
        ;;
    esac

    #如果返回的key是enter,那么直接进入第一个目录项,然后退出
    if [[ -z "${key}" ]]; then
        echo 0
        return 0
    fi

    #计算要返回的index(不考虑array_tags中第一个表示enter键的icon)
    for ((i = 1; i < "${tags_size}"; i++)); do
        if [[ "${key}" == "${array_tags[*]:$i:1}" ]]; then
            echo "${i}"
            return 0
        fi
    done

    #到了这里,说明key不是array_tags数组里面的某个标签,那么直接退出
    echo -1
    return 0
}

#参数1:表示匹配数组中目录项的index
#参数2:存储分支池的数组
function do_checkout() {
    local index
    index=$1
    shift

    local array_matched=()
    array_matched=("${@}")

    #bash array indexing starts at 0
    #zsh array indexing starts at 1
    #for code which works in both bash and zsh, you need to use the offset:length syntax rather than the [subscript] syntax
    #所以,要取得数组中第一个元素,需要这样写${array[*]:0:1}
    local p="${array_matched[*]:$index:1}"
    git checkout "${p}" >/dev/null 2>&1
}

function main() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "the current directory is not a git repository"
        exit 1
    fi

    if [[ $1 == "-h" ]] || (($# != 1)); then
        help_info
        exit 1
    fi

    #处理命令行参数
    pattern=$1

    local array_matched
    array_matched=($(do_match))

    #如果存在完美匹配的话,就只保留数组里面的第一个元素
    local first_branch_in_array="${array_matched[*]:0:1}"
    if [[ "${first_branch_in_array}" == "${pattern}" ]]; then
        array_matched=("${array_matched[*]:0:1}")
    fi

    #匹配项的数量
    local matched_size
    matched_size="${#array_matched[@]}"

    #计算index
    local index
    #如果一个都没有匹配上的话,那么index=-1,直接退出
    if (("${matched_size}" == 0)); then
        index=-1
    #如果只有一个匹配项的话,那么index=0,直接进入而无需打印,然后退出
    elif (("${matched_size}" == 1)); then
        index=0
    #到这里,说明匹配项多于1个
    else
        #打印选项
        print_matched_path "${array_matched[@]}"

        #读取键盘输入
        local key
        key=$(read_keyboard)

        #处理键盘输入,获取一个表示匹配数组中目录项的index
        index=$(process_key "${key}")
        #检查这个index是否超过了匹配数组的大小,因为如果超过了,就说明用户所选择的那个标签根本就没有参与打印
        #因为要考虑到第一个用于"回车"的标签,所以这里要减去1
        if (("${index}" > $(("${matched_size}" - 1)))); then
            index=-1
        fi
    fi

    #输出一个空行
    if (("${index}" != -1)) && (("${index}" != 0)); then
        echo
    fi

    #根据index的不同值来退出/进入
    if (("${index}" != -1)); then
        #echo '最后返回的index:'"${index}"
        do_checkout "${index}" "${array_matched[@]}"
    fi

    return 0
}

main "$@"
