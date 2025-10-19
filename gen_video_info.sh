#!/usr/bin/env bash

#=ffmpeg
#@使用ffprobe命令来生成一个视频文件的流信息,并将信息存储到一个info文件中
#@该脚本主要是被其它脚本调用
#@usage:
#@script.sh video_file

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
        if ! command -v "${tool}" &>/dev/null; then
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
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=("VIDEO_INFOS_DIR")
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local video_file="${1}"
    local video_file_basename
    local video_file_basename_without_ext
    video_file_basename=$(basename "${video_file}")
    video_file_basename_without_ext="${video_file_basename%.*}"

    local info_file
    mkdir -p "${VIDEO_INFOS_DIR}"
    info_file="${VIDEO_INFOS_DIR}/${video_file_basename_without_ext}"

    if [ ! -f "${video_file}" ]; then
        echo "error:${video_file} does not exist"
        exit 1
    fi

    ffprobe -v error -select_streams a -show_entries stream=index,codec_name,codec_long_name,codec_type,disposition:stream_tags=language,title -of default=noprint_wrappers=0:nokey=0 "${video_file}" > "${info_file}"

    ffprobe -v error -select_streams s -show_entries stream=index,codec_name,codec_long_name,codec_type,disposition:stream_tags=language,title -of default=noprint_wrappers=0:nokey=0 "${video_file}" >> "${info_file}"
}

main "${@}"
