#!/usr/bin/env bash

#=tools
#@视频下载器:参数文件中的每一行都是一个url,脚本会依次下载这些url所指定的视频
#@usage:
#@script.sh urls_file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script urls_file" >&2
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
    if (("$#" != 1)); then
        usage
    fi
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

main() {
    REQUIRED_TOOLS=(ffmpeg yt-dlp)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local file="${1}"
    if [[ ! -f "${file}" ]]; then
        echo "${file} is not a file"
        exit 1
    fi

    #如果文件的最后一行内容后面没有一个结尾的换行符:\n的话,那么read会:
    #读取到最后一行内容
    #但返回状态为非0(失败)
    #while循环就不会执行该行的循环体
    #解决办法:
    #read返回失败(最后一行没有换行符)时:
    #read -r line为false
    #但如果line仍然有内容
    #[[ -n "$line" ]]为true
    #while则继续执行该行的循环体
    while IFS= read -r line || [[ -n "$line" ]]; do
        #跳过空行,空白行,注释行
        #去掉前后空白用于判断
        trimmed="${line#"${line%%[![:space:]]*}"}"       #左侧去空白
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}" #右侧去空白
        #跳过空行或只有空白的行
        [[ -z "$trimmed" ]] && continue
        #跳过注释行(以#开头)
        [[ $trimmed == \#* ]] && continue

        echo "==================================="
        video_downloader.sh "${line}"
        #生成30到60之间的随机数(包含30和60)
        local sleep_seconds=$((RANDOM % 31 + 30))
        echo "sleep ${sleep_seconds} seconds ..."
        sleep "${sleep_seconds}"
    done < "${file}"
}

main "${@}"
