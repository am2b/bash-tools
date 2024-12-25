#!/usr/bin/env bash

#=gpg
#@使用gpg对称加密,解密一个字符串
#@usage:
#@encrypt:
#@script.sh -e string
#@decrypt:
#@script.sh -d string

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "encrypt:${script} -e string_to_encrypt"
    echo "decrypt:${script} -d string_to_decrypt"
    exit 1
}

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi

    if [[ -z "${2}" ]]; then
        usage
    fi
}

process_opts() {
    while getopts ":hed" opt; do
        case $opt in
        h)
            usage
            ;;
        e)
            ENCRYPT=true
            ;;
        d)
            DECRYPT=true
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

do_encrypt() {
    #对称加密,使用GPG加密明文字符串,输出为ASCII编码(可打印的字符串)
    ENCRYPTED_STRING=$(echo -n "$STRING" | gpg --batch --yes --passphrase "$KEYCHAIN_PASSWORD" --symmetric --armor)

    if [[ $? -eq 0 ]]; then
        echo "encrypted text:"
        echo "${ENCRYPTED_STRING}"

    else
        echo "error:encryption failed"
        exit 1
    fi
}

do_decrypt() {
    DECRYPTED_STRING=$(echo "$STRING" | gpg --quiet --batch --yes --passphrase "$KEYCHAIN_PASSWORD" --decrypt)

    if [[ $? -eq 0 ]]; then
        echo "decrypted text:"
        echo "${DECRYPTED_STRING}"
    else
        echo "error:decryption failed"
        exit 1
    fi
}

main() {
    check_parameters "${@}"

    process_opts "${@}"

    shift $((OPTIND - 1))

    STRING="$1"

    #从macOS钥匙串获取GPG对称加密的密码
    KEYCHAIN_PASSWORD=$(security find-generic-password -s "gpg-symmetric" -a "${MAIL_GMAIL_MAIN}" -w)

    if [[ "$ENCRYPT" == true ]]; then
        do_encrypt
    elif [[ "$DECRYPT" == true ]]; then
        do_decrypt
    fi
}

main "${@}"
