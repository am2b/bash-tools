#!/usr/bin/env bash

#=tmux
#@根据toml配置文件来创建tmux会话,窗口,pane
#@usage:
#@script.sh config.toml

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script config.toml" >&2
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
        case "$opt" in
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
    REQUIRED_TOOLS=(tomlctl)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    local config="${1}"
    if [[ ! -f "${config}" ]]; then
        echo "error:配置文件错误"
        exit 1
    fi

    local session_name
    local window_num
    session_name=$(tomlctl get "${config}" session.name)
    window_num=$(tomlctl get "${config}" session.window_num)
    #在后台创建一个会话
    tmux new-session -d -s "${session_name}"

    #遍历数组表:windows
    local window
    local window_name
    local split
    local split_direction
    local split_ratio

    local window_index

    #先创建window_num - 1个窗口
    for ((i = 1; i < "${window_num}"; i++)); do
        window_index=$((i + 1))
        tmux new-window -t "${session_name}":"${window_index}" -n "${i}"
    done

    for ((i = 0; i < "${window_num}"; i++)); do
        window="windows[$i]"
        window_name=$(tomlctl get "${config}" "${window}".name)
        #重命名窗口
        window_index=$((i + 1))
        tmux select-window -t "${window_index}"
        tmux rename-window "${window_name}"

        split=$(tomlctl get "${config}" "${window}".split)
        if [[ "${split}" == "true" ]]; then
            split_direction=$(tomlctl get "${config}" "${window}".split_direction)
            split_ratio=$(tomlctl get "${config}" "${window}".split_ratio)
            tmux split-window -"${split_direction}" -l "${split_ratio}"
        fi
    done

    #定位光标在第1个窗口
    tmux next-window

    #进入会话
    tmux attach -t "${session_name}"
}

main "${@}"

#配置文件:
#[session]
#name = "work"
#window_num = 2

#[[windows]]
#name = "window-1"
#split = true
#split_direction = "h"
#split_ratio = 65

#[[windows]]
#name = "window-2"
#split = false
