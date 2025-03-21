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
    local dir_cache
    local token_cache
    local chat_id_cache
    #注意:不要在这里使用XDG_CACHE_HOME,因为hammerspoon里面没有export这个环境变量
    dir_cache=~/.cache/telegram
    if [[ ! -d "${dir_cache}" ]]; then
        mkdir -p "${dir_cache}"
    fi
    token_cache="${dir_cache}"/token
    chat_id_cache="${dir_cache}"/chat_id

    if [[ -f "${token_cache}" ]]; then
        token=$(cat "${token_cache}")
    else
        token=$(security find-generic-password -s "telegram-clipboard-bot" -a "clipboard_bot" -w)
        echo "${token}" >"${token_cache}"
    fi

    if [[ -f "${chat_id_cache}" ]]; then
        chat_id=$(cat "${chat_id_cache}")
    else
        chat_id=$(security find-generic-password -s "telegram_chat_id" -a "${name}" -w)
        echo "${chat_id}" >"${chat_id_cache}"
    fi

    curl -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d "chat_id=${chat_id}" \
        -d "text=$(pbpaste)" &>/dev/null
}

main "${@}"
