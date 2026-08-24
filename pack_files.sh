#!/usr/bin/env bash

#=pack
#@加密打包给定的文件
#@该脚本是对pack_dir.sh的补充,因为通过pack_dir.sh将给定目录下的文件分别单独打包后,以后可能又会给这个目录下新增文件,那么继续单独打包新增的文件就是pack_files.sh这个脚本的用处了
#@打包后的文件名格式:file.mkv -> file.7z,file.tar.gz -> file.7z,所以文件名中尽量不要包含无谓的'.'
#@打包后的文件会和原始的文件处于同一目录下
#@usage:
#@script.sh file1.mp4 file2.mkv ...

#设置utf-8环境支持多语言文件名
export LC_ALL=en_US.UTF-8

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file1.mp4 file2.mkv ..." >&2
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
    if (("$#" < 1)); then
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
        password=$(<"${password_file}")
    fi

    #打包
    local pack_name
    local file_dir
    local file_name
    for arg; do
        file_dir=$(dirname -- "${arg}")
        file_name=$(basename -- "${arg}")
        pack_name=$(generate_packname "${arg}")
        (
            if ! cd -- "${file_dir}"; then
                echo "ERROR:无法进入目录:${file_dir}" >&2
                exit 1
            fi

            if [[ ! -f "${file_name}" ]]; then
                echo "ERROR:文件不存在或不是普通文件:${file_name}" >&2
                exit 1
            fi

            if ! 7z a -p"${password}" -mhe=on -mx=0 "${pack_name}" "${file_name}" &>/dev/null; then
                echo "打包失败:${pack_name}" >&2
                exit 1
            fi
        )
    done
}

main "${@}"
