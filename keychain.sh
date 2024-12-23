#!/usr/bin/env bash

#=password
#@add,update,delete password in keychain
#@usage:
#@add:
#@keychain.sh -a --[or ,] item_name account_name 'password'
#@update:
#@keychain.sh -u --[or ,] item_name account_name 'new_password'
#@delete:
#@keychain.sh -d --[or ,] item_name account_name
#@get:
#@keychain.sh -g --[or ,] item_name account_name

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "keychain is only available on mac"
    exit 1
fi

parse_options() {
    if [[ "$#" -lt 2 ]]; then
        echo "usage:parse_options option_string -options option_values --[or ,] position_values"
        exit 1
    fi

    #关联数组存储选项及其值
    declare -g -A OPTIONS=()

    declare -g SHIFT_VALUE=0

    local option_string="$1"
    #移除option_string参数,剩下的是选项和位置参数
    shift
    ((SHIFT_VALUE++))

    #如果option_string里面包含了数字
    if [[ "$option_string" =~ [0-9] ]]; then
        #提取出第一个数字
        first_digit=$(echo "$option_string" | grep -o "[0-9]" | head -n 1)
        echo "error:option string:\"$option_string\" contains the number '$first_digit'"
        exit 1
    fi

    #如果option_string里面包含了除:和;以外的其它字符
    if [[ "$option_string" =~ [^a-zA-Z:\;] ]]; then
        #提取第一个出现的非法字符
        first_invalid_char=$(echo "$option_string" | grep -o "[^a-zA-Z:;]" | head -n 1)
        echo "error:option string:\"$option_string\" contains an invalid character '$first_invalid_char'"
        exit 1
    fi

    #如果option_string里面包含了大写字母
    if [[ "$option_string" =~ [A-Z] ]]; then
        #提取第一个出现的大写字母
        first_uppercase=$(echo "$option_string" | grep -o "[A-Z]" | head -n 1)
        echo "error:option string:\"$option_string\" contains an uppercase letter '$first_uppercase'"
        exit 1
    fi

    #如果option_string里面包含了重复的字母
    declare -A letter_count
    #遍历字符串中的每个字符
    for ((i = 0; i < ${#option_string}; i++)); do
        letter="${option_string:$i:1}"
        #仅检查小写字母
        if [[ "$letter" =~ [a-z] ]]; then
            if [[ ${letter_count["$letter"]} ]]; then
                echo "error:option string:\"$option_string\" contains a repeated letter '$letter'"
                exit 1
            else
                letter_count["$letter"]=1
            fi
        fi
    done

    #确保,和--周围有且仅有一个空格
    #字符串的形式
    local parameters="${*}"
    if [[ "${parameters}" =~ "--" ]] || [[ "${parameters}" =~ "," ]]; then
        parameters=$(echo "$parameters" | sed -E 's/ *, */ , /g; s/ *-- */ -- /g')
    fi
    #把字符串转换为普通数组
    IFS=' ' read -r -a parameters <<<"$parameters"
    set -- "${parameters[@]}"

    # 用于存储拆分后的选项
    declare -a split_options=()
    while [[ "$1" != "" && "$1" != "--" && "$1" != "," ]]; do
        # 检查是否有连在一起的选项
        if [[ "$1" =~ ^-[a-zA-Z]{2,}$ ]]; then
            # 提取 "-" 前缀
            prefix="${1:0:1}"
            # 提取后续字符作为选项组
            option_group="${1:1}"
            # 逐字符解析option_group,将每个选项拆分成独立的选项
            for ((i = 0; i < ${#option_group}; i++)); do
                split_options+=("${prefix}${option_group:$i:1}")
            done
        else
            # 非连在一起的选项,直接添加
            split_options+=("$1")
        fi
        shift
    done

    #用于当前函数外部
    #option_string,拆分后的选项和剩余的参数
    declare -g SCRIPT_ARGUMENTS=()
    SCRIPT_ARGUMENTS+=("${option_string}")
    SCRIPT_ARGUMENTS+=("${split_options[@]}")
    SCRIPT_ARGUMENTS+=("${@}")

    #用于当前函数内部
    #将拆分后的选项和剩余的参数重新插入参数列表
    set -- "${split_options[@]}" "$@"

    local opt
    local multiple_values
    #每个选项负责吃掉自己的参数值,如果有的话
    while [[ "$1" != "" ]]; do
        case "$1" in
        -- | ,)
            shift
            ((SHIFT_VALUE++))
            break
            ;;
        -*)
            #获取选项字母
            #${1:1:1}表示对第一个参数$1执行字符串切片操作,从第二个字符开始(索引为1),取1个字符.因此,opt=${1:1:1}的作用是将$1的第二个字符赋值给变量opt
            opt=${1:1:1}
            #如果opt在option_string的描述里面
            if [[ "$option_string" == *"$opt"* ]]; then
                if [[ "$option_string" == *"$opt;"* ]]; then
                    #处理多个参数的选项
                    multiple_values=()
                    shift
                    ((SHIFT_VALUE++))
                    while [[ "$1" != "" && "$1" != -* && "$1" != "--" && "$1" != "," ]]; do
                        multiple_values+=("$1")
                        shift
                        ((SHIFT_VALUE++))
                    done
                    if [[ ${#multiple_values[@]} -eq 0 ]]; then
                        echo "error:option -$opt requires at least one value."
                        exit 1
                    fi
                    OPTIONS["$opt"]="${multiple_values[*]}"
                elif [[ "$option_string" == *"$opt:"* ]]; then
                    #处理单个参数的选项
                    shift
                    ((SHIFT_VALUE++))
                    if [[ "$1" != "" && "$1" != -* && "$1" != "--" && "$1" != "," ]]; then
                        OPTIONS["$opt"]="$1"
                        shift
                        ((SHIFT_VALUE++))
                        #如果给:多于1个值的话
                        if [[ "$1" != "" && "$1" != -* && "$1" != "--" && "$1" != "," ]]; then
                            echo "error:option -$opt just requires one value."
                            exit 1
                        fi
                    else
                        echo "error:option -$opt requires a value."
                        exit 1
                    fi
                else
                    #处理布尔选项
                    shift
                    ((SHIFT_VALUE++))
                    if [[ "$1" == "" || "$1" == -* || "$1" == "--" || "$1" == "," ]]; then
                        OPTIONS["$opt"]=0
                    else
                        echo "error:option -$opt does not require a value."
                        exit 1
                    fi
                fi
            else
                echo "error:unrecognized option -$opt"
                exit 1
            fi
            ;;
        *)
            echo "usage:parse_options option_string -options option_values --[or ,] position_values"
            exit 1
            ;;
        esac
    done
}

parse_options "audg" "${@}"
set -- "${SCRIPT_ARGUMENTS[@]}"
shift "${SHIFT_VALUE}"

if [[ "${#OPTIONS[@]}" -lt 1 ]]; then
    echo "you did not give any option"
    exit 1
fi

if [[ "${#OPTIONS[@]}" -gt 1 ]]; then
    echo "only one operation can be performed at a time"
    exit 1
fi

SERVICE_NAME="${1}"
ACCOUNT_NAME="${2}"
PASSWORD="${3}"

#检查是否有同名项
function check_existing_item {
    security find-generic-password -s "$SERVICE_NAME" -a "$ACCOUNT_NAME" &>/dev/null
    #如果找到了就返回0,否则返回非0
    return $?
}

add() {
    check_existing_item
    if check_existing_item; then
        echo "该项已存在,未添加新项"
    else
        security add-generic-password -a "${ACCOUNT_NAME}" -s "${SERVICE_NAME}" -w "${PASSWORD}"
        echo "已成功添加密码到钥匙串"
    fi
}

delete() {
    if check_existing_item; then
        security delete-generic-password -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" &> /dev/null
        echo "已成功从钥匙串中删除密码项"
    else
        echo "未找到要删除的密码项"
    fi
}

update() {
    if check_existing_item; then
        security delete-generic-password -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" &> /dev/null
        security add-generic-password -a "${ACCOUNT_NAME}" -s "${SERVICE_NAME}" -w "${PASSWORD}"
        echo "已成功更新密码项"
    else
        security add-generic-password -a "${ACCOUNT_NAME}" -s "${SERVICE_NAME}" -w "${PASSWORD}"
        echo "未找到要更新的密码项,已添加新密码项到钥匙串"
    fi
}

get() {
    if check_existing_item; then
        security find-generic-password -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" -w
    else
        echo "未找到密码项"
    fi
}

if [[ "${OPTIONS[a]}" == "0" ]]; then
    add
elif [[ "${OPTIONS[u]}" == "0" ]]; then
    update
elif [[ "${OPTIONS[d]}" == "0" ]]; then
    delete
elif [[ "${OPTIONS[g]}" == "0" ]]; then
    get
fi
