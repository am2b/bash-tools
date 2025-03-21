#!/usr/bin/env bash

#=mac
#@退出音乐和照片App,然后结束Amphetamine的当前会话,然后让mac休眠
#@usage:
#@script.sh

#系统设置 > 隐私与安全性 > 自动化 > iTerm:
#System Events
#Amphetamine

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #退出音乐和照片应用(如果它们正在运行)
    if pgrep -x "Music" >/dev/null; then
        osascript -e 'tell application "Music" to quit'
    fi

    if pgrep -x "Photos" >/dev/null; then
        osascript -e 'tell application "Photos" to quit'
    fi

    #取消Amphetamine计时(如果存在)
    if pgrep -x "Amphetamine" >/dev/null; then
        #按下:ctrl + option + cmd + a(自己在Amphetamine里面设置的结束会话的快捷键)
        osascript -e 'tell application "System Events" to key code 0 using {control down, option down, command down}'
    fi

    #使用osascript触发macOS的锁屏快捷键(ctrl + cmd + q)
    osascript -e 'tell application "System Events" to key code 12 using {control down, command down}'
}

main "${@}"
