#!/usr/bin/env bash

#设置utf-8环境支持多语言文件名
export LC_ALL=en_US.UTF-8

#=pack
#@解压给定目录下的每个7z文件到参数所指定的目录
#@usage:
#@script.sh dir_from dir_to

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script dir_from dir_to"
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
    if (("$#" < 1)) || (("$#" > 2)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #注意:
    #7z不会自动展开~
    #realpath也不会自动展开~,所以应该使用$HOME

    #压缩文件所在的目录
    local dir_from
    dir_from=$(realpath "${1}")
    if [[ ! -d "${dir_from}" ]]; then
        echo "错误:${dir_from}目录不存在"
        exit 1
    fi

    #解压到的目录
    local dir_to
    dir_to=$(realpath "${2:-/Volumes/T7/解压后}")
    if [[ ! -d "${dir_to}" ]]; then
        mkdir -p "${dir_to}"
    fi
    #如果目录非空,则清空
    if [ -n "$(find "$dir_to" -mindepth 1 -print -quit)" ]; then
        #使用find命令安全删除所有内容(包括隐藏文件和子目录)
        find "$dir_to" -mindepth 1 -exec rm -rf {} +
    fi

    #密码
    local password
    local password_file=/tmp/7z-choice
    if [[ ! -f "${password_file}" ]]; then
        if ! password=$(security find-generic-password -s "7z" -a "choice" -w 2>/dev/null); then
            echo "error: failed to retrieve password from keychain" >&2
            exit 1
        fi
        touch "${password_file}" && chmod 600 "${password_file}"
        printf "%s" "${password}" >"${password_file}"
    else
        password=$(<"${password_file}")
    fi

    #解压
    find "${dir_from}" -maxdepth 1 -type f -name '*.7z' | while read -r archive; do
        echo "正在解压:${archive##*/}"
        if ! 7z x "${archive}" -p"${password}" -o"${dir_to}" &>/dev/null; then
            echo "❌解压失败:${archive##*/}"
            exit 1
        fi
    done

    #校验
    cd "${dir_to}" || exit 1

    cp "${dir_from}"/*.txt "${dir_to}"
    local txt_file
    #防止没有匹配时*.txt被当作字面量
    shopt -s nullglob
    txt_files=(*.txt)
    if [ ${#txt_files[@]} -eq 1 ]; then
        txt_file="${txt_files[0]}"
    else
        echo "错误:找到${#txt_files[@]}个txt文件" >&2
        exit 1
    fi

    find . -maxdepth 1 -type f ! -name "${txt_file}" ! -name ".DS_Store" | while read -r file; do
        local sha
        sha=$(sha256sum "${file}" | awk '{print $1}')
        if ! grep -qF "$sha" "$txt_file"; then
            echo "错误:${file}与原始文件不一致"
            exit 1
        fi
    done

    echo "验证完毕,完全一致"

    #发送通知
    osascript -e 'display notification "验证完毕,完全一致" with title "解压完成" sound name "Glass"'
}

main "${@}"
