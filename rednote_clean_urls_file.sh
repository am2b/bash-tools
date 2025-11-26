#!/usr/bin/env bash

#=rednote
#@从小红书获取到的视频链接包含非url内容,该脚本会提取urls到一个输出文件:file.urls
#@usage:
#@script.sh origin_urls_file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script origin_urls_file" >&2
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
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local origin_urls_file="${1}"
    if [ ! -f "$origin_urls_file" ]; then
        echo "文件不存在: $origin_urls_file"
        exit 1
    fi

    local output="${origin_urls_file}.urls"

    #提取URL → 去除CR → 去重 → 排序(字典序)
    grep -o 'http://xhslink\.com/[^ ]*' "$origin_urls_file" | tr -d '\r' | sort -u > "$output"

    count=$(wc -l < "$output")
    echo "提取了${count}个urls..."
}

main "${@}"
