#!/usr/bin/env bash

#设置utf-8环境支持多语言文件名
export LC_ALL=en_US.UTF-8

#=pack
#@分别打包给定目录下的每个视频文件
#@如果有字幕文件的话,会把字幕和视频打包到一个包里面
#@打包后的文件和源文件在同一个目录下
#@无法将video-01.mp4和video-02.mp4打包到同一个包里面,所以遇到这种情况请手动打包
#@usage:
#@script.sh dir

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

random_filename() {
    local length=20

    local filename
    filename=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c $length)

    echo "${filename}"
}

generate_random_name() {
    local pack_sisters_data_dir
    pack_sisters_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pack_sisters"
    if [[ ! -d "${pack_sisters_data_dir}" ]]; then
        mkdir -p "${pack_sisters_data_dir}"
    fi

    local unique_filenames_file
    unique_filenames_file="${pack_sisters_data_dir}/unique_filenames"
    if [[ ! -f "${unique_filenames_file}" ]]; then
        touch "${unique_filenames_file}"
    fi

    local random_name
    local times=0
    while :; do
        random_name=$(random_filename)

        ((times++))

        #如果生成的文件名是唯一的
        #grep -qFx:实现精确全行匹配检查
        #-q:若找到匹配行,返回状态码0,否则返回1
        #-F:固定字符串匹配,禁用正则表达式,将模式识别为普通文本
        #-x:整行匹配:模式需与目标行完全一致
        if ! grep -qFx "$random_name" "$unique_filenames_file"; then
            echo "$random_name" >>"$unique_filenames_file"
            break
        fi

        #安全机制:防止无限循环
        if ((times > 100)); then
            echo "警告:为了生成一个唯一的文件名,已经尝试太多次了" >&2
            exit 1
        fi
    done

    echo "${random_name}"
}

normalize_basename() {
    local filename=$(basename -- "$1")
    #去除最后一个后缀
    local basename=${filename%.*}

    #英文字母统一小写,其他字符保持原样
    echo "$basename" | tr '[:upper:]' '[:lower:]'
}

generate_sha256() {
    sha256sum "$1" | awk '{print $1}'
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #目标目录
    local sisters_dir
    sisters_dir=$(realpath "${1}")
    if [[ ! -d "${sisters_dir}" ]]; then
        echo "error:参数所指定的目录不存在"
        exit 1
    fi

    #进入目标目录
    cd "${sisters_dir}" || { echo "错误:无法进入指定目录:${sisters_dir}"; exit 1; }

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
        #shell内建,效率高(比cat更快)
        #能保留所有字符,包括空格和特殊符号
        #不解释反斜杠或其他转义字符
        password=$(<"${password_file}")
    fi

    #因为要把字幕和视频文件打包到一起
    declare -A sisters_groups

    #遍历目录并建立分组
    while IFS= read -r -d '' file; do
        key=$(normalize_basename "$file")

        #添加文件到分组
        if [[ -n "${sisters_groups[$key]}" ]]; then
            sisters_groups["$key"]+=$'\n'"$file"
        else
            sisters_groups["$key"]="$file"
        fi
    done < <(find . -maxdepth 1 -type f ! -name '.DS_Store' -print0)
    #! -name '.DS_Store':排除名称为.DS_Store的文件

    #打包
    local pack_name

    local record_file
    record_file=$(basename "${sisters_dir}").txt

    for key in "${!sisters_groups[@]}"; do
        pack_name=$(generate_random_name).7z

        #读取分组文件列表
        #IFS=$'\n':以换行符为分隔,把关联数组的value拆成多个字段,放入数组files
        #-d '':指定"定界符"为空字符\0来终止读取(而不是默认的换行符),这种用法常用于<<<的场景中,确保可以读取多行内容
        #-r:防止反斜杠转义,原样读取文本
        #-a files:将读取到的字段存入数组files中,每个元素是按IFS分割的结果
        #<<<:是bash的here string语法:把右边的字符串当作标准输入传给命令
        IFS=$'\n' read -d '' -r -a files <<<"${sisters_groups[$key]}"

        #执行打包操作
        #"${files[@]##*/}":其中的##*/:表示删除最后一个/(包括/)前的所有内容,也就是删除路径部分从而剩下文件名本身部分
        #${var##*/}:表示从变量var的值中删除最长匹配的*/前缀,即保留最后一个斜杠后的部分
        #'##'是"最长匹配",'#'是"最短匹配"
        #&>/dev/null:将标准输出(stdout)和标准错误(stderr)都重定向到/dev/null
        #&>/dev/null只是重定向输出,不会对命令的退出码(即$?)有影响
        if ! 7z a -p"${password}" -mhe=on -mx=0 "${pack_name}" "${files[@]##*/}" &>/dev/null; then
            echo "打包失败:${pack_name}" >&2
            exit 1
        fi

        #写入记录文件
        #格式:
        #xxxyyyzzz.7z:
        #video.mp4 -> sha256
        #video.str -> sha256
        #-------------------------
        echo "${pack_name}" >>"${record_file}"
        local sha
        for file in "${files[@]}"; do
            sha=$(generate_sha256 "$file")
            printf "%s -> %s\n" "${file##*/}" "${sha}" >>"${record_file}"
        done
        echo "-------------------------" >>"${record_file}"
    done

    #最后存储7z文件的目录
    local storage_dir
    storage_dir="${sisters_dir}-"$(generate_random_name)
    mkdir -p "${storage_dir}"
    mv ./*.7z "${storage_dir}"
    mv "${record_file}" "${storage_dir}"

    #将storage_dir存储起来,以便于可以在打包完成后自动解压,验证
    local pack_sisters_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/pack_sisters"
    echo "${storage_dir}" > "${pack_sisters_data_dir}/storage"
}

main "${@}"
