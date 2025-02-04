#!/usr/bin/env bash

#=tools
#@usage:
#@send_mail.sh "subject" "body" recipient

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script \"subject\" \"body\" \"recipient\""
    exit 1
}

check_parameters() {
    if (("$#" != 3)); then
        usage
    fi
}

check_tools() {
    #检查是否安装了msmtp
    if ! command -v msmtp &>/dev/null; then
        echo "msmtp未安装,正在通过Homebrew安装..."

        # 检查是否安装了Homebrew
        if ! command -v brew &>/dev/null; then
            echo "Homebrew未安装,请先安装Homebrew"
            exit 1
        fi

        #使用Homebrew安装msmtp
        brew install msmtp

        #检查是否安装成功
        if ! command -v msmtp &>/dev/null; then
            echo "msmtp安装失败,请检查Homebrew设置"
            exit 1
        else
            echo "msmtp安装成功"
        fi
    fi
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

do_send() {
    subject=$1
    body=$2
    recipient=$3

    nohup sh -c "printf 'To: %s\nSubject: %s\n\n%s\n' \"$recipient\" \"$subject\" \"$body\" | msmtp \"$recipient\"" >/dev/null 2>&1 &
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    check_tools

    do_send "${@}"
}

main "${@}"
