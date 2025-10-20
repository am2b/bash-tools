#!/usr/bin/env bash

#=ffmpeg
#@删除视频文件的其它的音轨和字幕,仅保留参数所指定语言的音轨和字幕,默认为eng
#@usage:
#@script.sh video_file [language]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script video_file" >&2
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
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local video_file="${1}"
    if [ ! -f "${video_file}" ]; then
        echo "error:${video_file} dose not exist"
        exit 1
    fi

    local lang=${2:-eng}

    #视频文件的后缀名
    local suffix="${video_file##*.}"
    local output_file="${video_file%.*}_${lang}.${suffix}"

    local video_file_basename
    video_file_basename=$(basename "${video_file}")

    #note:ffmpeg swallow stdin
    if ! ffmpeg -hide_banner -v error \
        -i "${video_file}" \
        -map 0:v \
        -map 0:a:m:language:"${lang}" \
        -map 0:s:m:language:"${lang}" \
        -c copy "${output_file}" < /dev/null; then
        echo "❌ ffmpeg 处理失败:${video_file_basename}"
        exit 1
    else
        echo "✅ ${video_file_basename}"
    fi
}

main "${@}"
