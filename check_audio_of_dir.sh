#!/usr/bin/env bash

#=ffmpeg
#@检查一个目录中的视频文件是否有参数所指定语言的audio流
#@usage:
#@script.sh dir [eng]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir [language]" >&2
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

    local dir="${1}"
    if [ ! -d "${dir}" ]; then
        echo "error:${dir} does not exist"
        exit 1
    fi

    local lang=${2:-eng}

    #清空${VIDEO_INFOS_DIR}目录
    if [[ -d "${VIDEO_INFOS_DIR}" ]]; then
        find "${VIDEO_INFOS_DIR}" -mindepth 1 -delete
    fi

    while IFS= read -r -d '' video_file; do
        check_audio_of_file.sh "${video_file}" "${lang}"
        echo
    done < <(find "${dir}" -path './.git' -prune -o \( -type f ! -name '.DS_Store' -print0 \) | sort -z)

}

main "${@}"
