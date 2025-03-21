#!/usr/bin/env bash

#=telegram
#@获取用户的chat_id
#@usage:
#@发送消息给某个bot
#@script.sh TOKEN

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "发送消息给某个bot"
    echo "$script TOKEN"
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
    if (("$#" != 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    TOKEN="$1"
    URL="https://api.telegram.org/bot$TOKEN/getUpdates"

    # 获取更新信息
    response=$(curl -s "$URL")

    # 解析最新一条消息的 chat_id
    chat_id=$(echo "$response" | jq -r '.result | last.message.chat.id')

    # 检查是否成功获取 chat_id
    if [[ -z "$chat_id" || "$chat_id" == "null" ]]; then
        echo "❌ No messages found or failed to fetch chat_id."
        exit 1
    fi

    # 让机器人发送 chat_id
    MESSAGE="Your chat_id is:$chat_id"
    send_url="https://api.telegram.org/bot$TOKEN/sendMessage"

    send_response=$(curl -s -X POST "$send_url" -d "chat_id=$chat_id" -d "text=$MESSAGE")

    # 检查是否发送成功
    if echo "$send_response" | jq -e '.ok' >/dev/null; then
        echo "✅ Chat ID 已发送到 Telegram！"
    else
        echo "❌ Failed to send message."
    fi
}

main "${@}"
