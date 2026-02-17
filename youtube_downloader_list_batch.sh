#!/usr/bin/env bash

#=youtube
#@视频下载器:
#@专用于下载长list
#@不是一次性把list全部下载完,而是分批次来下载
#@可以登录后下载,也可以不登录下载
#@usage:
#@未登录:
#@script.sh list_url [batch_size]
#@登录后:
#@script.sh -c list_url [batch_size]

#播放列表URL
playlist_url=""
#默认每次下载5个视频
batch_size=5
#是否使用cookies(默认为false)
use_cookies=false
#播放列表中视频的数量
total_videos=0
#记录文件
record_file=""

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script list_url [batch_size]" >&2
    echo "$script -c list_url [batch_size]" >&2
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
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    playlist_url="${1}"
    if [[ $# == 2 ]]; then batch_size="${2}"; fi

    #确保提供了播放列表URL
    if [[ -z "$playlist_url" ]]; then
        echo "Error: You must provide a playlist URL."
        exit 1
    fi

    #生成记录文件名
    record_file="/tmp/youtube_$(echo -n "$playlist_url" | sha256sum | cut -d ' ' -f 1).txt"

    #检查记录文件是否存在
    if [[ -f "$record_file" ]]; then
        #读取记录文件中的播放列表URL和视频总数
        saved_url=$(sed -n '1p' "$record_file")
        total_videos=$(sed -n '2p' "$record_file")

        if [[ "$saved_url" != "$playlist_url" ]]; then
            echo "Error: The playlist URL in the record file does not match the current playlist URL."
            exit 1
        fi
    else
        #如果记录文件不存在,获取视频总数并创建记录文件
        total_videos=$(yt-dlp --flat-playlist --get-id "$playlist_url" | wc -l)
        echo "$playlist_url" > "$record_file"
        echo "$total_videos" >> "$record_file"
        #设上次下载的视频index是0
        echo 0 >> "$record_file"
    fi

    #检查播放列表是否为空
    if [[ $total_videos -eq 0 ]]; then
        echo "Error: The playlist is empty or cannot be accessed."
        exit 1
    fi

    #获取已下载的最大视频编号
    last_downloaded=$(tail -n 1 "$record_file")

    #计算从哪个视频开始下载
    start=$((last_downloaded + 1))
    end=$((last_downloaded + batch_size))

    #检查如果到达播放列表末尾,就结束脚本
    if [[ $start -gt $total_videos ]]; then
        echo "All videos are already downloaded."
        exit 0
    fi

    #防止下载超出播放列表的视频数量
    if [[ $end -gt $total_videos ]]; then
        end=$total_videos
    fi

    #下载视频
    echo "Starting download from video $start to $end..."

    opts=(
        --format "bestvideo+bestaudio/best"
        --merge-output-format mp4
        -o "%(playlist_index)03d-%(title)s.%(ext)s"
        --sleep-interval 10
        --max-sleep-interval 30
    )
    [[ "$use_cookies" == true ]] && opts+=(--cookies-from-browser chrome)

    yt-dlp "${opts[@]}" --playlist-start "$start" --playlist-end "$end" "$playlist_url"
    STATUS=$?
    if (("${STATUS}" != 0)); then
        echo "============================="
        echo "❌ 下载失败(错误码:$STATUS)"
        echo "============================="
    fi

    #更新已下载的视频编号并记录文件名
    echo "$end" >> "$record_file"
}

main "${@}"
