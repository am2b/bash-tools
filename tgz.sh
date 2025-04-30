#!/usr/bin/env bash

#=tools
#@bring tar gzip zip and 7z together
#@usage:tgz.sh -h

#split:
#split -b 100m archive.7z archive.7z --verbose
#cat archive.7z* > archive.7z

function usage() {
    cat <<EOF
tgz.sh:
bring tar gzip zip and 7z together

Usage:
tgz.sh [options] arguments

Options:
-h:show this [h]elp
-p:use custom [p]assword, do not use default password
-c:[c]reate the archive.tar[.tar.gz|.tgz|.zip|.7z|.tar.7z|.t7z],note:.DS_Store and .git folder will be excluded
-l:[l]ist the files in an archive
-e:[e]xtract the files to current dir
-d:extract the files to the specified [d]ir
-v:show the process [v]erbosely

Examples:
create:
tgz.sh -c archive.tar[.tar.gz|.tgz|.zip] --[or ,] file_1 file_2 dir_1 dir_2

create with default password:
tgz.sh -c archive.7z[.tar.7z|.t7z] --[or ,] file_1 file_2 dir_1 dir_2

create with custom password:
tgz.sh -c archive.7z[.tar.7z|.t7z] -p "password" --[or ,] file_1 file_2 dir_1 dir_2

list:
tgz.sh -l archive.tar[.tar.gz|.tgz | .zip | .7z | .tar.7z |.t7z]

extract the files to current dir
tgz.sh -e archive.tar[.tar.gz|.tgz | .zip | .7z | .tar.7z |.t7z] -p 'password'

extract the files to the specified dir
tgz.sh -e archive.tar[.tar.gz|.tgz | .zip | .7z | .tar.7z |.t7z] -d dir -p 'password'
EOF
}

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

    #如果文件或者文件夹的名字里面包含空格的话,先将空格替换为_^_SPACE_^_
    SPACE_REPLACEMENT="_^_SPACE_^_"
    local parameters=()
    #将参数中的空格替换为对应数量的SPACE_REPLACEMENT
    for p in "$@"; do
        p="${p// /${SPACE_REPLACEMENT}}"
        parameters+=("$p")
    done
    #这里注释的原因:密码可能包含,
    #确保,和--周围有且仅有一个空格
    #local parameters_string="${parameters[*]}"
    #if [[ "${parameters_string}" =~ "--" ]] || [[ "${parameters_string}" =~ "," ]]; then
    #    parameters_string=$(echo "$parameters_string" | sed -E 's/ *, */ , /g; s/ *-- */ -- /g')
    #fi
    #把字符串转换为普通数组
    #IFS=' ' read -r -a parameters <<<"$parameters_string"
    #unset IFS
    #再把SPACE_REPLACEMENT替换为相应数量的空格
    for p in "${parameters[@]}"; do
        if [[ "$p" == *"${SPACE_REPLACEMENT}"* ]]; then
            p="${p//${SPACE_REPLACEMENT}/ }"
        fi
        parameters_final+=("$p")
    done

    set -- "${parameters_final[@]}"

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
                    #值其实是一个字符串,多个值是被空格分隔的
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
                        OPTIONS["$opt"]="0"
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

parse_options 'c:p:l;e;d:vh' "${@}"
set -- "${SCRIPT_ARGUMENTS[@]}"
shift "${SHIFT_VALUE}"

ext_tar="tar"
ext_tar_gz="tar.gz"
ext_tgz="tgz"
ext_zip="zip"
ext_tar_7z="tar.7z"
ext_t7z="t7z"
ext_7z="7z"

function get_password() {
    password="${OPTIONS[p]}"

    if [[ -z "${password}" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SERVICE_NAME="command-line-package"
            ACCOUNT_NAME="7z"
            password=$(security find-generic-password -s "${SERVICE_NAME}" -a "${ACCOUNT_NAME}" -w)
        else
            echo "没有提供密码,也没有适用的密码管理工具"
            exit 1
        fi
    fi

    echo "${password}"
}

function is_verbose() {
    if [[ "${OPTIONS[v]}" == "0" ]]; then
        echo "v"
    else
        echo ""
    fi
}

function get_archive_extension() {
    local archive_name="$1"
    #检查文件名是否包含"."
    if [[ "$archive_name" == *.* ]]; then
        #使用参数扩展提取从第一个"."开始的后缀
        echo "${archive_name#*.}"
    else
        #如果没有后缀,返回空字符串
        echo ""
    fi
}

function create_archive() {
    local archive_name="${OPTIONS[c]}"

    local ext
    ext=$(get_archive_extension "$archive_name")

    local password
    password=$(get_password)

    local v
    v=$(is_verbose)

    if [[ "$ext" == "${ext_tar}" ]]; then
        tar --exclude='.DS_Store' --exclude='.git' -c"${v}"f "$archive_name" "$@"
    elif [[ "$ext" == "${ext_tar_gz}" ]] || [[ "$ext" == "${ext_tgz}" ]]; then
        tar --exclude='.DS_Store' --exclude='.git' -cz"${v}"f "$archive_name" "$@"
    elif [[ "$ext" == "${ext_zip}" ]]; then
        zip -x "*.DS_Store" "*.git/*" -r "$archive_name" "$@" &>/dev/null
    elif [[ "$ext" == "${ext_7z}" ]]; then
        #files encrypted using the .7z format are encrypted with AES-256 encryption by default
        #-mx=0 means copy mode (no compression)
        7z -xr!'.DS_Store' -xr!'.git' a -p"${password}" -mhe=on -mx=0 "${archive_name}" "$@" &>/dev/null
    elif [[ "$ext" == "${ext_tar_7z}" ]] || [[ "$ext" == "${ext_t7z}" ]]; then
        #remove suffix:.7z,.tar.7z,.t7z
        local archive_name_without_suffix
        archive_name_without_suffix="${archive_name%%.*}"
        local archive_tar_name
        archive_tar_name="${archive_name_without_suffix}".tar
        tar --exclude='.DS_Store' --exclude='.git' -c"${v}"f "$archive_tar_name" "$@"
        7z a -p"${password}" -mhe=on -mx=0 "${archive_name}" "$archive_tar_name" &>/dev/null
        #remove the tar file
        rm "$archive_tar_name"
    else
        usage && exit 1
    fi
}

function list_archive() {
    local password
    password=$(get_password)

    local count=$(echo "${OPTIONS[l]}" | wc -w | tr -d '[:space:]')
    #or:
    #local array=(${OPTIONS[l]})
    #local count="${#array[@]}"

    for archive_name in ${OPTIONS[l]}; do
        local ext
        ext=$(get_archive_extension "$archive_name")

        if [[ "$ext" == "${ext_tar}" ]]; then
            tar -tf "$archive_name"
        elif [[ "$ext" == "${ext_tar_gz}" ]] || [[ "$ext" == "${ext_tgz}" ]]; then
            tar -ztf "$archive_name"
        elif [[ "$ext" == "${ext_zip}" ]]; then
            unzip -v "$archive_name"
        elif [[ "$ext" == "${ext_7z}" ]] || [[ "$ext" == "${ext_tar_7z}" ]] || [[ "$ext" == "${ext_t7z}" ]]; then
            7z l -p"${password}" "$archive_name"
        else
            usage && exit 1
        fi

        ((count--))
        if [[ "${count}" -gt 0 ]]; then
            echo "---------------"
        fi
    done
}

function extract() {
    local archive_name
    archive_name="$1"

    local password
    password=$(get_password)

    local ext
    ext=$(get_archive_extension "$archive_name")

    local dir="${OPTIONS[d]}"

    local v
    v=$(is_verbose)

    if [[ "$ext" == "${ext_tar}" ]]; then
        if [[ -n "${dir}" ]]; then
            tar -x"${v}"f "$archive_name" -C "$dir"
        else
            tar -x"${v}"f "$archive_name"
        fi
    elif [[ "$ext" == "${ext_tar_gz}" ]] || [[ "$ext" == "${ext_tgz}" ]]; then
        if [[ -n "${dir}" ]]; then
            tar -zx"${v}"f "$archive_name" -C "$dir"
        else
            tar -zx"${v}"f "$archive_name"
        fi
    elif [[ "$ext" == "${ext_zip}" ]]; then
        if [[ -n "${dir}" ]]; then
            unzip "$archive_name" -d "${dir}" &>/dev/null
        else
            unzip "$archive_name" &>/dev/null
        fi
    elif [[ "$ext" == "${ext_7z}" ]]; then
        local output
        if [[ -n "${dir}" ]]; then
            output=$(7z x -p"${password}" -o"${dir}" "$archive_name" 2>&1)
        else
            output=$(7z x -p"${password}" "$archive_name" 2>&1)
        fi

        if echo "$output" | grep -iq "wrong password"; then
            #打印包含"wrong password"的行
            echo "$output" | grep -i "wrong password"
            exit 1
        fi
    elif [[ "$ext" == "${ext_tar_7z}" ]] || [[ "$ext" == "${ext_t7z}" ]]; then
        local output
        output=$(7z x -p"${password}" "$archive_name" 2>&1)
        if echo "$output" | grep -iq "wrong password"; then
            #打印包含"wrong password"的行
            echo "$output" | grep -i "wrong password"
            exit 1
        fi

        #remove suffix:.tar.7z,.t7z
        local archive_name_without_suffix
        archive_name_without_suffix="${archive_name%%.*}"
        local archive_tar_name
        archive_tar_name="${archive_name_without_suffix}".tar
        if [[ -n "${dir}" ]]; then
            tar -x"${v}"f "$archive_tar_name" -C "$dir"
        else
            tar -x"${v}"f "$archive_tar_name"
        fi
        rm "$archive_tar_name"
    fi
}

function extract_archive() {
    #extract the files to the specified dir
    if [[ -n "${OPTIONS[d]}" ]] && [[ ! -d "${OPTIONS[d]}" ]]; then
        mkdir -p "${OPTIONS[d]}"
    fi

    for archive_name in ${OPTIONS[e]}; do
        extract "$archive_name"
    done
}

if [[ "${OPTIONS[h]}" == '0' ]]; then
    usage
    exit 0
fi

#create archive
if [[ -n "${OPTIONS[c]}" ]]; then
    create_archive "$@"
    exit 0
fi

#list archive
if [[ -n "${OPTIONS[l]}" ]]; then
    list_archive "$@"
    exit 0
fi

#extract archive
if [[ -n "${OPTIONS[e]}" ]]; then
    extract_archive "$@"
    exit 0
fi
