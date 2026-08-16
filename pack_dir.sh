#!/usr/bin/env bash

#=pack
#@分别打包给定目录下的每个文件,包含隐藏文件,但是不包含.DS_Store,不递归子目录
#@打包后的文件名格式:file.mkv -> file.7z,file.tar.gz -> file.7z,所以文件名中尽量不要包含无谓的'.'
#@打包结束后,打包后的文件夹会和原始的文件夹处于并列的位置
#@usage:
#@script.sh dir

#设置utf-8环境支持多语言文件名
export LC_ALL=en_US.UTF-8

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir" >&2
    exit 1
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

generate_packname() {
    local filename
    filename=$(basename -- "$1")
    #去除最长的后缀
    echo "${filename%%.*}.7z"
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #目标目录
    local target_dir
    target_dir=$(realpath "${1}")
    if [[ ! -d "${target_dir}" ]]; then
        echo "error:参数所指定的目录不存在"
        exit 1
    fi

    #进入目标目录
    cd "${target_dir}" || { echo "错误:无法进入指定目录:${target_dir}"; exit 1; }

    #密码
    local password
    local password_file=/tmp/7z-115-dir
    if [[ ! -f "${password_file}" ]]; then
        if ! password=$(security find-generic-password -s "7z" -a "115-dir" -w 2>/dev/null); then
            echo "error: failed to retrieve password from keychain" >&2
            exit 1
        fi
        touch "${password_file}" && chmod 600 "${password_file}"
        printf "%s" "${password}" >"${password_file}"
    else
        #shell内建,效率高(比cat更快)
        #能保留所有字符,包括空格和特殊符号
        #不解释反斜杠或其他转义字符
        password=$(<"${password_file}")
    fi

    #打包
    local pack_name
    while IFS= read -r file; do
        pack_name=$(generate_packname "${file}")
        if ! 7z a -p"${password}" -mhe=on -mx=0 "${pack_name}" "${file}" &>/dev/null; then
            echo "打包失败:${pack_name}" >&2
            exit 1
        fi
    done < <(find_files_in_a_dir.sh -d "${target_dir}" -i .DS_Store)

    #最后存储7z文件的目录
    local storage_dir
    storage_dir="${target_dir}-backup"
    mkdir -p "${storage_dir}"
    mv ./*.7z "${storage_dir}"
}

main "${@}"
