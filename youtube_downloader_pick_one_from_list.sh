#!/usr/bin/env bash

#=youtube
#@视频下载器:
#@专用于从一个list里面,挑选一个来下载
#@可以登录后下载,也可以不登录下载
#@usage:
#@未登录:
#@script.sh list_url index
#@登录后:
#@script.sh -c list_url index

#播放列表URL
playlist_url=""
#挑选的那一个
index=0
#是否使用cookies(默认为false)
use_cookies=false

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script list_url index" >&2
    echo "$script -c list_url index" >&2
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
    if (("$#" != 2)); then
        usage
    fi
}

process_opts() {
    while getopts ":hc" opt; do
        case $opt in
            h)
                usage 0
                ;;
            c)
                use_cookies=true
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
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    playlist_url="${1}"
    index="${2}"

    #确保提供了播放列表URL
    if [[ -z "$playlist_url" ]]; then
        echo "Error: You must provide a playlist URL."
        exit 1
    fi

    #获取要下载的视频的名字
    name=$(yt-dlp --no-warnings --get-filename -o "%(playlist_index)03d-%(title)s.%(ext)s" --playlist-start "$index" --playlist-end "$index" "$playlist_url")
    read -r -n 1 -p "下载:${name}? [Y/n]" answer
    echo
    case "${answer}" in
    'y' | 'Y' | '')
        down_flag=1
        ;;
    *)
        down_flag=0
        ;;
    esac

    if (("${down_flag}" == 0)); then exit 1; fi

    opts=(
        --format "bestvideo+bestaudio/best"
        --merge-output-format mp4
        -o "%(playlist_index)03d-%(title)s.%(ext)s"
    )
    [[ "$use_cookies" == true ]] && opts+=(--cookies-from-browser chrome)

    yt-dlp "${opts[@]}" --playlist-start "$index" --playlist-end "$index" "$playlist_url"
    STATUS=$?
    if (("${STATUS}" != 0)); then
        echo "============================="
        echo "❌ 下载失败(错误码:$STATUS)"
        echo "============================="
    fi
}

main "${@}"
