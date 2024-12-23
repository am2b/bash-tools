#!/usr/bin/env bash

#=tools
#@directory jump through fuzzy matching
#@usage:
#@fuzzy_jump.sh pattern1 pattern2 ...

#用于标记每个待选项的标签(最多标记10个选项)
array_tags=('\uf0e7' 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i')
tags_size="${#array_tags[@]}"

pattern=''

ARRAY_MATCHED=()
function get_down_matched()
{
    #收集向下方向的路径
    local dirs
    #因为不能使用绝对路径去参与匹配,绝对路径前面的部分会污染匹配
    dirs=($(fd --relative-path --type d .))

    #与pattern进行匹配
    for d in "${dirs[@]}"; do
        ARRAY_MATCHED+=($(echo "${d}" | sed -n "/${pattern}/p"))
    done
}

#打印匹配的项目
function print_matched_path()
{
    echo 'Press Enter to enter the first directory.'

    local right_arrow='\uf061'

    #同时遍历匹配的数组和标签数组,这两个数组的大小不同,所以按照小的数组来遍历
    local matched_size="${#ARRAY_MATCHED[@]}"
    local min=$(( tags_size < matched_size ? tags_size : matched_size ))
    for (( i = 0; i < "${min}"; ++i ))
    do
        echo -e -n '['"${array_tags[*]:$i:1}"']' ' '
        echo -e -n "${right_arrow}${right_arrow}${right_arrow}" ' '
        #打印的时候,用~来替换具体的$HOME
        #echo $(echo "${ARRAY_MATCHED[*]:$i:1}" | sed "s|$(realpath $HOME)|~|")
        echo "${ARRAY_MATCHED[*]:$i:1}"
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

    #到了这里,说明key不是array_tags数组里面的某个标签,所以直接退出
    echo -1
    return 0
}

#参数:表示匹配数组中目录项的index
function do_cd()
{
    local index
    index=$1

    local p="${ARRAY_MATCHED[*]:$index:1}"
    cd "${p}" || return 1
}

function main()
{
    #收集目录
    get_down_matched

    #匹配项的数量
    local matched_size
    matched_size="${#ARRAY_MATCHED[@]}"

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
        print_matched_path

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
        do_cd "${index}" "${ARRAY_MATCHED[@]}"

        #do ls:
        eza
    fi

    return 0
}

#处理命令行参数
pattern="$*"
#用bash的方式全局替换
pattern=${pattern//' '/.*}

main
