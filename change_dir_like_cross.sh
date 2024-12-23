#!/usr/bin/env bash

#=tools
#@横向:在兄弟目录之间跳转
#@纵向:在祖孙目录之间跳转(向上至\~或者/,向下受fd命令的--max-results选项限制)
#@附近:在附近(向上至\~或者/,向下受fd命令的--max-results选项限制,以及每个祖先的兄弟目录)跳转:

#用于标记每个待选项的标签(最多标记10个选项)
array_tags=('\uf0e7' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i')
tags_size="${#array_tags[@]}"

option=""
abs_starting_dir=$(realpath .)
pattern=""

help_info()
{
    local script
    script=$(basename "$0")

cat << EOF
print this [h]elp
. $script -h

横向(兄弟):
. $script -[b]rothers pattern

纵向(祖孙)(向上至~或者/,向下受fd命令的--max-results选项限制):
. $script -[u]p pattern
. $script -[d]own pattern

附近(向上至~或者/,向下受fd命令的--max-results选项限制,以及每个祖先的兄弟目录):
. $script -[n]earby pattern
EOF
}

#返回给定目录的兄弟目录的绝对路径
function get_brothers_matched()
{
    local abs_cur_dir
    abs_cur_dir="${abs_starting_dir}"
    if (( "$#" == 1 )); then
        abs_cur_dir="${1}"
    fi

    local parent
    parent=$(dirname "${abs_cur_dir}")

    local array_matched=()
    #--hidden:包含隐藏的目录
    array_matched=($(fd --max-depth 1 --absolute-path --type d --exclude $(basename "${abs_cur_dir}") "${pattern}" "${parent}"))

    echo "${array_matched[@]}"
}

#返回向上方向匹配的绝对目录
function get_up_matched()
{
    #一直往上,直到遇到~,或者遇到了root
    local array_dirs=()

    #收集给定目录的祖先目录的绝对路径
    local parent
    parent=$(dirname "${abs_starting_dir}")
    until [[ "${parent}" == $(realpath "$HOME") ]] || [[ "${parent}" == '/' ]]
    do
        array_dirs+=("${parent}")
        parent=$(dirname "${parent}")
    done

    local array_dirs_size
    array_dirs_size="${#array_dirs[@]}"

    #进行匹配
    local array_matched=()

    #如果命令行参数没有给出pattern,那么就表示想cd ..
    if [[ -z "${pattern}" ]]; then
        #array_matched=($(dirname "${abs_starting_dir}"))
        if (( "${array_dirs_size}" >= 1 )); then
            array_matched=("${array_dirs[*]:0:1}")
        fi
    #如果pattern是..
    #那么就表示想cd .. && cd ..
    elif [[ "${pattern}" == '..' ]]; then
        if (( "${array_dirs_size}" >= 2 )); then
            array_matched=("${array_dirs[*]:1:1}")
        fi
    #如果pattern是...
    #那么就表示想cd .. && cd .. && cd ..
    elif [[ "${pattern}" == '../..' ]]; then
        if (( "${array_dirs_size}" >= 3 )); then
            array_matched=("${array_dirs[*]:2:1}")
        fi
    else
        for p in "${array_dirs[@]}"
        do
            #注意:在这里如果给${pattern}两侧包围了双引号的话,则表示按照字符串字面量来匹配,而不是按照正则表达式来匹配
            if [[ $(basename "${p}") =~ ${pattern} ]]; then
                array_matched+=("${p}")
            fi
        done
    fi

    echo "${array_matched[@]}"
}

#返回向下方向匹配的绝对目录
function get_down_matched()
{
    local array_matched=()

    #如果命令行参数没有给出pattern,并且当前目录下只有一个子目录,那么就表示想进入那个唯一的子目录
    if [[ -z "${pattern}" ]]; then
        array_matched=($(fd --max-depth 1 --absolute-path --type d))
        if (( "${#array_matched[@]}" != 1 )); then
            array_matched=()
        fi
    else
        #--hidden:包含隐藏的目录
        array_matched=($(fd --min-depth 1 --max-results 100 --absolute-path --type d "${pattern}"))
    fi

    echo "${array_matched[@]}"
}

#返回给定目录的附近目录的绝对路径
function get_nearby_matched()
{
    #附近(向上)
    local array_dirs_up=()
    array_dirs_up=($(get_up_matched))

    #附近(向下)
    local array_dirs_down=()
    array_dirs_down=($(get_down_matched))

    #附近(兄弟)
    #local array_dirs_brothers=()
    #array_dirs_brothers=($(get_brothers_matched))

    #每个祖先的兄弟
    local array_dirs_brothers_of_ancestors=()
    local cur_dir
    cur_dir="${abs_starting_dir}"
    until [[ "${cur_dir}" == $(realpath "$HOME") ]] || [[ "${cur_dir}" == '/' ]]
    do
        array_dirs_brothers_of_ancestors+=($(get_brothers_matched "${cur_dir}"))
        cur_dir=$(dirname "${cur_dir}")
    done

    local array_matched=()
    array_matched=("${array_dirs_up[@]}" "${array_dirs_down[@]}" "${array_dirs_brothers_of_ancestors[@]}")

    echo "${array_matched[@]}"
}

#查找是否存在一个项与pattern是完美匹配的,如果找到了完美匹配,那么就要对数组进行重新组合,把完美匹配放到数组的最开始
#参数:已经匹配的数组
function find_exact_matched()
{
    #已经匹配的数组
    local array_matched=()
    array_matched=("${@}")

    #遍历数组,看看有没有一个完美匹配的项,如果有的话,记下index
    local perfect_index=-1
    local matched_size="${#array_matched[@]}"

    for (( i = 0; i < "${matched_size}"; i++ )); do
        if [[ $(basename "${array_matched[*]:$i:1}") == "${pattern}" ]]; then
            perfect_index="${i}"
            #如果存在多个完美的匹配,那么只考虑第一次的完美匹配
            break
        fi
    done

    #如果找到了完美匹配,那么对数组进行重新组合,把完美匹配放到最开始
    if (( "${perfect_index}" != -1 )); then
        array_matched=("${array_matched[@]:$perfect_index:1}" "${array_matched[@]:0:$perfect_index}" "${array_matched[@]:$((perfect_index + 1))}")
    fi

    echo "${array_matched[@]}"
}

#打印匹配的项目
#参数:已经匹配的数组
function print_matched_path()
{
    echo 'Press Enter to enter the first directory.'

    #已经匹配的数组
    local array_matched=()
    array_matched=("${@}")

    local right_arrow='\uf061'

    #同时遍历匹配的数组和标签数组,这两个数组的大小不同,所以按照小的数组来遍历
    local matched_size="${#array_matched[@]}"
    local min=$(( tags_size < matched_size ? tags_size : matched_size ))
    for (( i = 0; i < "${min}"; ++i ))
    do
        echo -e -n '['"${array_tags[*]:$i:1}"']' ' '
        echo -e -n "${right_arrow}${right_arrow}${right_arrow}" ' '
        #打印的时候,用~来替换具体的$HOME
        echo $(echo "${array_matched[*]:$i:1}" | sed "s|$(realpath $HOME)|~|")
    done

    local num_not_printed
    num_not_printed=$(( "${matched_size}" - "${tags_size}" ))
    if (( "${num_not_printed}" > 0 )); then
        echo "There are ${num_not_printed} entries that have not been printed."
    fi

    echo 'Press q to quit.'
}

#读取键盘输入
function read_keyboard()
{
    #读取键盘
    local key
    #注意:-n在source script.sh的时候没有效果,所以这里使用-k
    read -r -k 1 key
    
    echo "${key}"
}

#处理键盘输入
#返回一个索引,该索引值表示array_tags里面的index,也表示了"匹配数组中的目录index"
#返回index为-1就表示直接退出
function process_key()
{
    local key
    key=$1

    case "$key" in
    #按下q键退出
        'q'|'Q')
            echo -1
            return 0
            ;;
    esac

    #如果返回的key是enter,那么直接进入第一个目录项,然后退出
    #the \n at the end of the user's input is stripped off before assigning the value to the shell variable.so if the user just presses enter,the value will be the empty string.
    if [[ -z "${key}" ]]; then
        echo 0
        return 0
    fi

    #计算要返回的index(不考虑array_tags中第一个表示enter键的icon)
    for (( i = 1; i < "${tags_size}"; i++ ))
    do
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
#参数2:存储绝对目录池的数组
function do_cd()
{
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
    cd "${p}" || return 1
}

function main()
{
    #处理命令行参数
    option=$1
    pattern=$2

    #收集目录
    local array_matched=()

    #处理选项
    case "${option}" in
        "-h")
            help_info
            return 0
            ;;
        "-b")
            array_matched=($(get_brothers_matched))
            ;;
        "-u")
            array_matched=($(get_up_matched))
            ;;
        "-d")
            array_matched=($(get_down_matched))
            ;;
        "-n")
            array_matched=($(get_nearby_matched))
            ;;
        *)
            help_info
            return 0
            ;;
    esac

    #寻找完美匹配项,然后对匹配数组进行重组
    array_matched=($(find_exact_matched "${array_matched[@]}"))

    #匹配项的数量
    local matched_size
    matched_size="${#array_matched[@]}"

    #计算index
    local index
    #如果一个都没有匹配上的话,那么index=-1,直接退出
    if (( "${matched_size}" == 0 )); then
        index=-1
    #如果只有一个匹配项的话,那么index=0,直接进入而无需打印,然后退出
    elif (( "${matched_size}" == 1 )); then
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
        if (( "${index}" > $(( "${matched_size}" - 1 )) )); then
            index=-1
        fi
    fi

    #输出一个空行
    if (( "${index}" != -1 )) && (( "${index}" != 0 )); then
        echo
    fi

    #根据index的不同值来退出/进入
    if (( "${index}" != -1 )); then
        #echo '最后返回的index:'"${index}"
        do_cd "${index}" "${array_matched[@]}"

        #do ls:
        eza
    fi

    return 0
}

main "$1" "$2"
