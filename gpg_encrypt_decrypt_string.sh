#!/usr/bin/env bash

#=gpg
#@使用gpg对称加密/解密字符串(密码从macOS钥匙串获取)
#@usage:
#@gpg_encrypt_decrypt_string.sh -e string
#@gpg_encrypt_decrypt_string.sh -d -- '-----BEGIN PGP MESSAGE----- another line XXXXXXXXXX another line -----END PGP MESSAGE-----'

set -euo pipefail

usage() {
    local script
    script=$(basename "$0")
    cat >&2 << EOF
使用 GPG 对称加密/解密字符串。

密码从 macOS 钥匙串读取(service: gpg-symmetric, account: \$MAIL_GMAIL_MAIN)。

用法:
  $script -e <字符串>     加密
  $script -d <字符串>     解密

选项:
  -h    显示此帮助信息
EOF
    exit "${1:-1}"
}

main() {
    local mode=""
    while getopts ":hed" opt; do
        case "$opt" in
            h) usage 0 ;;
            e) mode="encrypt" ;;
            d) mode="decrypt" ;;
            \?)
                echo "error: unsupported option -$OPTARG" >&2
                usage 1
                ;;
            :)
                echo "error: option -$OPTARG requires an argument" >&2
                usage 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ -z "$mode" ]]; then
        echo "error: 必须指定 -e(加密) 或 -d(解密)" >&2
        usage 1
    fi

    if (($# != 1)); then
        echo "error: 需要一个字符串参数" >&2
        usage 1
    fi

    local string="$1"

    # 从钥匙串获取密码
    if ! command -v security &> /dev/null; then
        echo "error: 此脚本依赖 macOS 钥匙串 (security 命令)" >&2
        exit 1
    fi

    local passphrase
    if ! passphrase=$(security find-generic-password -s "gpg-symmetric" -a "${MAIL_GMAIL_MAIN:?需要设置环境变量 MAIL_GMAIL_MAIN}" -w 2> /dev/null); then
        echo "error: 无法从钥匙串获取密码" >&2
        exit 1
    fi
    if [[ -z "$passphrase" ]]; then
        echo "error: 钥匙串返回了空密码" >&2
        exit 1
    fi

    if [[ "$mode" == "encrypt" ]]; then
        local encrypted
        if ! encrypted=$(printf '%s' "$string" | gpg --batch --yes --passphrase-fd 3 --symmetric --armor 3<<< "$passphrase" 2> /dev/null); then
            echo "error: encryption failed" >&2
            exit 1
        fi
        echo "encrypted text:"
        echo "$encrypted"
    else
        local decrypted
        if ! decrypted=$(printf '%s' "$string" | gpg --batch --yes --quiet --passphrase-fd 3 --decrypt 3<<< "$passphrase" 2> /dev/null); then
            echo "error: decryption failed (密码错误或密文损坏?)" >&2
            exit 1
        fi
        echo "decrypted text:"
        echo "$decrypted"
    fi
}

main "$@"
