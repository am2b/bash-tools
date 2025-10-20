#!/usr/bin/env bash

#=ffmpeg
#@检查一个视频文件是否有参数所指定语言的audio流
#@usage:
#@script.sh video_file [eng]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script video_file [language]" >&2
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
    REQUIRED_ENVS=("VIDEO_INFOS_DIR")
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local video_file="${1}"
    if [ ! -f "${video_file}" ]; then
        echo "error:${video_file} does not exist"
        exit 1
    fi

    local lang=${2:-eng}

    local video_file_basename
    local video_file_basename_without_ext
    video_file_basename=$(basename "${video_file}")
    video_file_basename_without_ext="${video_file_basename%.*}"

    local info_file
    info_file="${VIDEO_INFOS_DIR}/${video_file_basename_without_ext}_audio"

    gen_video_audio_info.sh "${video_file}"
    check_audio_from_info_file.sh "${info_file}" "${lang}"
}

main "${@}"
