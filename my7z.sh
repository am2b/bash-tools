#!/usr/bin/env bash

#=pack
#@对7z打包操作的一个包装
#@注意:密码文件为./password[.txt]或./pass[.txt]或./pd[.txt]
#@注意:没有解包功能,解包命令:7z x pack.7z或者x pack.7z
#@usage:
#@script.sh files... dirs...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script files or dirs" >&2
    exit "${1:-1}"
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
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

check_parameters() {
    if (("$#" == 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

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
    pack_name="${pack_name}.7z"

    #密码
    local password
    local password_file
    #在执行脚本时命令行的路径下寻找密码文件password[.txt]或pass[.txt]或pd[.txt]
    while IFS= read -r line; do
        password_file="$line"
        break
    done < <(find . -maxdepth 1 -type f \( -name "password" -o -name "password.txt" -o -name "pass" -o -name "pass.txt" -o -name "pd" -o -name "pd.txt" \))
    if [[ -n "$password_file" ]]; then
        chmod 600 "${password_file}"
        password=$(<"${password_file}")
    fi

    #进入目录
    cd "${first_dir}" || exit 1

    #收集参数的basename
    local -a basenames=()
    for path in "$@"; do
        basenames+=("$(basename "$path")")
    done

    if [[ -n "${password}" ]]; then
        echo "正在加密打包:${pack_name}"
        7z a -t7z "${pack_name}" "${basenames[@]}" -mhe=on -mx=0 -p"${password}" -xr'!.DS_Store' -xr'!.git'
    else
        echo "正在打包:${pack_name}"
        7z a -t7z "${pack_name}" "${basenames[@]}" -mhe=on -mx=0 -xr'!.DS_Store' -xr'!.git'
    fi

    #脚本内部的路径
    local script_current_dir
    script_current_dir=$(pwd)

    #移动包到执行脚本时命令行的路径
    if [[ "${script_current_dir}" != "${cmd_line_dir}" ]]; then
        mv "${pack_name}" "${cmd_line_dir}"
    fi
}

main "${@}"
