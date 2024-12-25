#!/usr/bin/env bash

#=gpg
#@export public key and private key
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 0
}

while getopts "h" opt; do
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
shift $((OPTIND - 1))

if (("$#" > 0)); then
    usage
fi

#获取GPG密钥ID
KEY_ID=$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)

if [ -z "$KEY_ID" ]; then
    echo "Error: GPG key ID not found."
    exit 1
fi

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

# 导出公钥
gpg --armor --export "$KEY_ID" > public_key.asc
if [ $? -ne 0 ]; then
    echo "error: failed to export public key."
    exit 1
fi

# 导出私钥
agent_file="${HOME}"/.gnupg/gpg-agent.conf
private_key=private_key.asc
if [[ ! -f "${agent_file}" ]]; then
    echo "allow-loopback-pinentry" > "${agent_file}" 
fi

gpg --batch --pinentry-mode loopback --passphrase "$KEYCHAIN_PASSWORD" --armor --export-secret-keys "$KEY_ID" > "${private_key}"
if [ $? -ne 0 ]; then
    echo "error: failed to export private key."
    exit 1
fi

chmod 600 "${private_key}"

rm "${agent_file}"
