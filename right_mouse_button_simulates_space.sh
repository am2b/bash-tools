#!/usr/bin/env bash

#=hammerspoon
#@单击鼠标右键来模拟空格键
#@在约定的目录下创建一个约定好名字的文件来激活hammerspoon中的映射
#@usage:
#@script.sh on/off
#@script.sh status

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script on/off" >&2
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
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    mkdir -p "${XDG_DATA_HOME}"/hammerspoon
    FLAG_FILE="${XDG_DATA_HOME}/hammerspoon/right_mouse_button_simulates_space"

    case "$1" in
    on)
        touch "$FLAG_FILE"
        echo "Mouse right click -> Space key mapping ENABLED"
        ;;
    off)
        rm -f "$FLAG_FILE"
        echo "Mouse right click -> Space key mapping DISABLED"
        ;;
    status)
        if [ -f "$FLAG_FILE" ]; then
            echo "Mapping is currently ENABLED"
        else
            echo "Mapping is currently DISABLED"
        fi
        ;;
    *)
        usage
        ;;
    esac
}

main "${@}"
