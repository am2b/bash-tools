#!/usr/bin/env bash

#=rednote
#@下载单个小红书视频
#@注意:如果下载多个小红书视频的话,需要使用cookies信息(--cookies-from-browser chrome)(登录后)
#@usage:
#@下载原始视频:
#@script.sh url
#@下载压缩后的视频(参数为ID):
#@script.sh url 0/1/2...

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script url" >&2
    echo "$script url 0/1/2..." >&2
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
    if (("$#" < 1 || "$#" > 2)); then
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
    local id="${2}"

    local dir_direct="${REDNOTE_DOWNLOAD_PATH}/id/direct"
    local dir_0="${REDNOTE_DOWNLOAD_PATH}/id/0"
    mkdir -p "${dir_direct}"
    mkdir -p "${dir_0}"

    local ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    local ref="https://www.xiaohongshu.com/"

    if [[ -z "${id}" ]]; then
        #下载id:direct
        cd "${dir_direct}" || exit 1
        yt-dlp \
            --cookies-from-browser chrome \
            --user-agent "${ua}" \
            --referer "${ref}" \
            -f direct "${URL}"
        cd - > /dev/null || exit 1
    else
        #下载id:0
        cd "${dir_0}" || exit 1
        yt-dlp \
            --cookies-from-browser chrome \
            --user-agent "${ua}" \
            --referer "${ref}" \
            -f "${id}" "${URL}"
        cd - > /dev/null || exit 1
    fi

    STATUS=$?

    if (("${STATUS}" != 0)); then
        echo "============================="
        echo "❌ 下载失败(错误码:$STATUS)"
        echo "============================="
    fi
}

main "${@}"
