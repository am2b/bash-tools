#!/usr/bin/env bash

#=convenient
#@enter easy to type mode for typing like chinese
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 0
}

#以便于在easy type mode下可以使用别名
[[ -f /tmp/aliases ]] && source /tmp/aliases && shopt -s expand_aliases

if [[ $# -gt 1 ]] || [[ $# -eq 1 && "$1" != "-h" ]]; then
    usage
fi

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

#当前目录下所有的文件和子目录的名字(不递归)
mapfile -t all < <(fd --max-depth 1 --hidden .)
all_size="${#all[@]}"
#为了下面的[[:space:]]"${key}"[[:space:]]匹配,需要给数组的第一个元素前面加上一个空格,给最后一个元素后面加上一个空格
all_with_space=(' '"${all[@]:0:1}" "${all[@]:1:((all_size - 2))}" "${all[@]:((all_size - 1)):1}"' ')

#关联数组,key为easy to type字符,value为实际的文件/目录名
declare -A fd_map

#生成key
key_pool=({a..z})
key_pool_size="${#key_pool[@]}"
#当a-z的字母用完后,就从0开始用
num_key_start_from=0
#遍历key_pool是用
key_index=0
#总共生成了多少个key
total_generated_keys=0
function generate_key()
{
    while true; do
        if (( "${key_index}" < "${key_pool_size}" )); then
            #取key_pool里面的元素
            key="${key_pool[*]:"${key_index}":1}"
            ((++key_index))
        else
            key=$((num_key_start_from++))
        fi

        #判断用作key的字符是否和当前目录的某个文件名相同
        if [[ "${all_with_space[*]}" =~ [[:space:]]"${key}"[[:space:]] ]]; then
            continue
        else
            #走到这里,说明不和文件名相同
            #那么,是否和某个子目录名相同,子目录dir从fd返回后为dir/
            if [[ "${all_with_space[*]}" =~ [[:space:]]"${key}"'/'[[:space:]] ]]; then
                continue
            else
                #走到这里,说明也不和子目录名相同
                break
            fi
        fi
    done

    ((++total_generated_keys))
    RETURN_KEY="${key}"
}

#把用到的key给保存一下,因为关联数组的顺序跟栈一样
used_keys=()

#填充关联数组
for item in "${all[@]}"; do
    generate_key
    fd_map["${RETURN_KEY}"]="${item}"
    used_keys+=("${RETURN_KEY}")
done

#打印
for key in "${used_keys[@]}"; do
    echo "${key}" ' ---> ' "${fd_map[$key]}"
done
echo
echo 'press q to quit'

#读取命令
echo "The short file name must be wrapped in single quotes,like rm 'a'"
read -r -p 'input command:' input_cmd
if [[ "${input_cmd}" = 'q' ]]; then exit 0; fi

#对输入命令中的'key'进行替换,替换为'value'
#拿出输入命令中的'key'
#$1:string
#$2:IFS
#example:string_split_to_array abc,def , -> (abc def)
#get the return array of function:array=($(string_split_to_array $string ifs))
function string_split_to_array()
{
    local s
    local IFS
    local array
    s="$1"
    IFS="$2" read -r -a array <<< "$s"

    echo "${array[@]}"
}
split_input_cmd_to_array=($(string_split_to_array "${input_cmd}" \'))
input_key="${split_input_cmd_to_array[*]:1:1}"

#检查输入的'key'是否是一个有效的'key'
#0 is true
key_is_valid=1
for k in "${used_keys[@]}"; do
    if [[ "${key}" = "${k}" ]]; then
        key_is_valid=0
        break
    fi
done
#如果无效则退出
if (( "${key_is_valid}" == 1 )); then exit 1; fi
#拿出key对应的value
value="${fd_map[$input_key]}"

#用value去替换input_cmd里面的key
#$1:string
#$2:pattern
#$3:replacement
#example:string_replace abcabc b 0 -> a0ca0c
#example:string_replace abcabc bc 0 -> a0a0
function string_replace()
{
    local s
    local pattern
    local replacement
    s="$1"
    pattern="$2"
    replacement="$3"

    echo "${s//$pattern/$replacement}"
}
#注意:这里给'${input_key}'添加的单引号
input_cmd=$(string_replace "${input_cmd}" "'${input_key}'" "${value}")
#删除input_cmd里面的单引号
input_cmd=$(echo "${input_cmd}" | tr -d "'")

read -r -N 1 -p 'will execute:'"${input_cmd}"' [y/N]' continue_execute
#消除%
echo
case "${continue_execute}" in
    'y' | 'Y')
        #执行
        eval "${input_cmd}"
        ;;
    *)
        exit 0
        ;;
esac
