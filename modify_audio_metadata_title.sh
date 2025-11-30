#!/usr/bin/env bash

#=ffmpeg
#@修改音频文件的元数据:title
#@usage:
#@script.sh -t title input_audio output_audio

TITLE=""

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script -t title input_audio output_audio" >&2
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
    if (("$#" != 2)); then
        usage
    fi
}

process_opts() {
    while getopts ":ht:" opt; do
        case "$opt" in
        h)
            usage 0
            ;;
        t)
            TITLE=$OPTARG
            ;;
        *)
            echo "error:unsupported option -$opt" >&2
            usage
            ;;
        esac
    done
}

main() {
    REQUIRED_TOOLS=(ffmpeg)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    local input="${1}"
    local output="${2}"

    ffmpeg -i "${input}" -metadata title="${TITLE}" -c:a copy "${output}"
}

main "${@}"
