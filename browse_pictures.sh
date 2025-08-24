#!/usr/bin/env bash

#=hammerspoon
#@在约定的目录下创建一个约定好名字的文件来激活hammerspoon中的映射
#@在访达中选中一个图片文件,按下空格键,在预览的过程中按下left/right来copy图片到配置文件所指定的目录
#@也可以仅在访达中选中文件然后按下left/right来copy
#@配置文件:"${XDG_CONFIG_HOME}"/hammerspoon-modules/browse_pictures
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
    REQUIRED_TOOLS=("jq")
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local configFile="${XDG_CONFIG_HOME}"/hammerspoon-modules/browse_pictures
    if [[ ! -f "${configFile}" ]]; then
        echo "配置文件不存在"
        exit 1
    fi
    destDir=$(jq -r '.destDir // empty' "${configFile}")
    if [[ -z "$destDir" ]]; then
        echo "错误:配置文件中没有destDir" >&2
        exit 1
    fi
    #替换~
    destDir=${destDir/#\~/$HOME}
    mkdir -p "${destDir}"

    mkdir -p "${XDG_DATA_HOME}"/hammerspoon
    FLAG_FILE="${XDG_DATA_HOME}/hammerspoon/browse_pictures"

    case "$1" in
    on)
        touch "$FLAG_FILE"
        echo "Browse pictures -> Left/Right keys mapping ENABLED"
        ;;
    off)
        rm -f "$FLAG_FILE"
        echo "Browse pictures -> Left/Right keys mapping DISABLED"
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
