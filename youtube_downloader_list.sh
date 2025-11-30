#!/usr/bin/env bash

#=youtube
#@视频下载器:下载整个播放列表(未登录)
#@usage:
#@script.sh list_url

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script list_url" >&2
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

    local URL="${1}"

    #--sleep-interval 30 --max-sleep-interval 60:在"每次HTTP请求之间"sleep
    yt-dlp \
        -f "bestvideo+bestaudio" \
        --merge-output-format mp4 \
        --concurrent-fragments 10 \
        --yes-playlist \
        --sleep-interval 30 \
        --max-sleep-interval 60 \
        -o "%(playlist_index)03d-%(title)s.%(ext)s" \
        "${URL}"

    STATUS=$?

    if (("${STATUS}" != 0)); then
        echo "============================="
        echo "❌ 下载失败(错误码:$STATUS)"
        echo "============================="
    fi
}

main "${@}"
