#!/usr/bin/env bash

#=pack
#@用7z加密打包2次
#@注意:密码文件为./password[.txt]或./pass[.txt]或./pd[.txt]
#@注意:2次的密码分别在密码文件的第一行和第二行,第一行为内层密码,第二行为外层密码
#@注意:没有解包功能,解包命令:7z x pack.7z或者x pack.7z
#@usage:
#@script.sh files... dirs...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file[s]/dir[s]" >&2
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
}

check_envs() {
    if (("$#" == 0)); then
        return 0
    fi

    for var in "$@"; do
        #如果变量未导出或值为空
        if [ -z "$(printenv "$var" 2> /dev/null)" ]; then
            echo "error:this script uses unexported environment variables:${var}"
            return 1
        fi
    done

    return 0
}

check_parameters() {
    if (("$#" == 0)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case "$opt" in
            h)
                usage 0
                ;;
            *)
                echo "error:unsupported option -$opt" >&2
                usage
                ;;
        esac
    done
}

main() {
    REQUIRED_TOOLS=(7z)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    #执行脚本时命令行的路径
    local cmd_line_dir
    cmd_line_dir=$(pwd)

    #确保所有的参数都在同一个目录下
    local first_dir
    first_dir=$(dirname "$(realpath "$1")")

    #遍历所有参数并比较其目录
    for path in "$@"; do
        if [ ! -e "$path" ]; then
            echo "错误:'$path'不存在"
            exit 1
        fi

        local dir
        dir=$(dirname "$(realpath "$path")")
        if [ "$dir" != "$first_dir" ]; then
            echo "参数不在同一目录下"
            exit 1
        fi
    done

    #决定包的名字
    local pack_name
    if (($# > 1)); then
        pack_name=$(basename "$first_dir")
    else
        if [[ -d "${1}" ]]; then
            pack_name=$(basename "$1")
        else
            local base_name
            base_name=$(basename "$1")
            #移除后缀名
            pack_name="${base_name%.*}"
        fi
    fi
    pack_name_1="${pack_name}_1.7z"
    pack_name_2="${pack_name}.7z"

    #密码
    local password_file
    #在执行脚本时命令行的路径下寻找密码文件password[.txt]或pass[.txt]或pd[.txt]
    while IFS= read -r line; do
        password_file="$line"
        break
    done < <(find . -maxdepth 1 -type f \( -name "password" -o -name "password.txt" -o -name "pass" -o -name "pass.txt" -o -name "pd" -o -name "pd.txt" \))
    if [[ ! -f "${password_file}" ]]; then
        echo "密码文件不存在"
        exit 1
    fi

    local password_1
    local password_2
    if [[ -f "$password_file" ]]; then
        chmod 600 "${password_file}"
        password_1=$(sed -n "1p" "${password_file}")
        password_2=$(sed -n "2p" "${password_file}")
    fi

    if [[ -z "${password_1}" ]] || [[ -z "${password_2}" ]]; then
        echo "有一个密码为空"
        exit 1
    fi

    #进入目录
    cd "${first_dir}" || exit 1
    echo "${first_dir}"
    echo

    #收集参数的basename
    local -a basenames=()
    for path in "$@"; do
        basenames+=("$(basename "$path")")
    done

    echo "第1次加密打包:${pack_name_1}"
    7z a -t7z "${pack_name_1}" "${basenames[@]}" -mhe=on -mx=0 -p"${password_1}" -xr'!.DS_Store' -xr'!.git'
    echo "------------------------------"
    echo "第2次加密打包:${pack_name_2}"
    7z a -t7z "${pack_name_2}" "${pack_name_1}" -mhe=on -mx=0 -p"${password_2}"
    rm -rf "${pack_name_1}"

    #脚本内部的路径
    local script_current_dir
    script_current_dir=$(pwd)

    #移动包到执行脚本时命令行的路径
    if [[ "${script_current_dir}" != "${cmd_line_dir}" ]]; then
        mv "${pack_name}" "${cmd_line_dir}"
    fi

    if [[ -f "$password_file" ]]; then
        read -r -n 1 -p "是否要删除 '$password_file'？y/N " answer
        echo
        #使用${answer^^}将输入转换为大写,统一处理大小写差异
        if [[ "${answer^^}" == 'Y' ]]; then
            rm "${password_file}"
        fi
    fi
}

main "${@}"
