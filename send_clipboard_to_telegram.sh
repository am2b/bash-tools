#!/usr/bin/env bash

#=telegram
#@send the text in clipboard to telegram
#@usage
#@script.sh chat_partner_name

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script chat_partner_name"
    exit 1
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
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local name="${1}"
    local token
    local chat_id
    token=$(security find-generic-password -s "telegram-clipboard-bot" -a "clipboard_bot" -w)
    chat_id=$(security find-generic-password -s "telegram_chat_id" -a "${name}" -w)

    curl -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d "chat_id=${chat_id}" \
        -d "text=$(pbpaste)" &>/dev/null
}

main "${@}"
