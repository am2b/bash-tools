#!/usr/bin/env bash

#=gpg
#@使用gpg加密,解密某个文件
#@usage:
#@encrypt:
#@script.sh -e file
#@decrypt:
#@script.sh -d file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "encrypt:${script} -e file_to_encrypt"
    echo "decrypt:${script} -d file_to_decrypt"
    exit 1
}

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi

    if [[ -z "${2}" || ! -f "${2}" ]]; then
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
    # 使用公钥加密文件
    gpg --encrypt --recipient "$RECIPIENT" "$FILE"

    if [[ $? -eq 0 ]]; then
        echo "file encrypted successfully:${FILE}.gpg"
    else
        echo "error:encryption failed"
        exit 1
    fi
}

do_decrypt() {
    # 从 macOS 钥匙串获取 GPG 密钥的私钥密码
    KEYCHAIN_PASSWORD=$(security find-generic-password -s "gpg" -a "${MAIL_GMAIL_MAIN}" -w)
    if [[ $? -ne 0 ]]; then
        echo "error:did not get password from keychain."
        exit 1
    fi
    if [ -z "$KEYCHAIN_PASSWORD" ]; then
        echo "error: could not retrieve password from keychain."
        exit 1
    fi

    # 使用私钥解密文件
    gpg --quiet --batch --pinentry-mode loopback --passphrase "$KEYCHAIN_PASSWORD" --decrypt "$FILE" > "${FILE%.gpg}"

    if [[ $? -eq 0 ]]; then
        echo "file decrypted successfully:${FILE%.gpg}"
    else
        echo "error:decryption failed"
        exit 1
    fi
}

main() {
    check_parameters "${@}"

    process_opts "${@}"

    shift $((OPTIND - 1))

    FILE="$1"

    # 公钥的邮件地址
    RECIPIENT="${MAIL_GMAIL_MAIN}"

    if [[ "$ENCRYPT" == true ]]; then
        do_encrypt
    elif [[ "$DECRYPT" == true ]]; then
        do_decrypt
    fi
}

main "${@}"
