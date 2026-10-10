#!/usr/bin/env bash

#=gpg
#@export public key and private key
#@usage:
#@script.sh

set -u
set -o pipefail

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

KEY_FINGERPRINT="A6F9E06007EC64EA7902881311C2FFC068D2608B"

# macOS Keychain service name.
KEYCHAIN_SERVICE="gpg"

# macOS Keychain account.
KEYCHAIN_ACCOUNT="${MAIL_GMAIL_MAIN:-}"

# Output directory.
BACKUP_DIR="${PWD}"

# Output filenames.
PUBLIC_KEY_FILE="${BACKUP_DIR}/public_key.asc"
PRIVATE_KEY_FILE="${BACKUP_DIR}/private_key.asc"

# ----------------------------------------------------------------------------
# Usage
# ----------------------------------------------------------------------------

usage() {
    local script
    script="$(basename "$0")"

    cat << EOF
Usage:
  ${script} -h

This script exports the GPG public key and secret key specified by KEY_FINGERPRINT.

Output:
  ${PUBLIC_KEY_FILE}
  ${PRIVATE_KEY_FILE}
EOF
}

# ----------------------------------------------------------------------------
# Temporary files
# ----------------------------------------------------------------------------

TMP_PUBLIC=""
TMP_PRIVATE=""

cleanup() {
    #当cleanup函数被trap触发时,脚本即将退出,如果不保存$?,直接执行rm命令后,$?会变成rm的执行结果
    local rc=$?

    if [[ -n "${TMP_PUBLIC}" && -e "${TMP_PUBLIC}" ]]; then
        rm -f -- "${TMP_PUBLIC}"
    fi

    if [[ -n "${TMP_PRIVATE}" && -e "${TMP_PRIVATE}" ]]; then
        rm -f -- "${TMP_PRIVATE}"
    fi

    exit "${rc}"
}

#利用trap命令捕获多种信号,确保无论脚本是正常结束,报错退出还是被用户中断,都能自动删除生成的临时文件
trap cleanup EXIT INT TERM HUP

# ----------------------------------------------------------------------------
# Argument parsing
# ----------------------------------------------------------------------------

while getopts ":h" opt; do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        \?)
            echo "error: unsupported option -${OPTARG}" >&2
            usage >&2
            exit 2
            ;;
    esac
done

shift $((OPTIND - 1))

if (($# != 0)); then
    echo "error: unexpected argument: $1" >&2
    usage >&2
    exit 2
fi

# ----------------------------------------------------------------------------
# Validate configuration
# ----------------------------------------------------------------------------

if [[ -z "${KEY_FINGERPRINT}" ]]; then
    echo "error: KEY_FINGERPRINT is not configured." >&2
    exit 1
fi

if [[ -z "${KEYCHAIN_ACCOUNT}" ]]; then
    echo "error: MAIL_GMAIL_MAIN is not set." >&2
    exit 1
fi

# A modern OpenPGP primary-key fingerprint is normally 40 hexadecimal chars.
#[[:xdigit:]]:十六进制字符类,等价于[0-9a-fA-F]
#{40}:表示前面的字符类必须精确重复40次
if [[ ! "${KEY_FINGERPRINT}" =~ ^[[:xdigit:]]{40}$ ]]; then
    echo "error: KEY_FINGERPRINT must be a 40-character hexadecimal fingerprint." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Security defaults
# ----------------------------------------------------------------------------

# Files created by this script should not be accessible by group/others.
umask 077

# ----------------------------------------------------------------------------
# Check required commands
# ----------------------------------------------------------------------------

if ! command -v gpg > /dev/null 2>&1; then
    echo "error: gpg not found." >&2
    exit 1
fi

if ! command -v security > /dev/null 2>&1; then
    echo "error: macOS security command not found." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Verify that the requested public key exists
# ----------------------------------------------------------------------------

if ! gpg --batch --quiet --list-keys "${KEY_FINGERPRINT}" > /dev/null 2>&1; then
    echo "error: public key not found:" >&2
    echo "  ${KEY_FINGERPRINT}" >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Verify that the requested secret key exists
# ----------------------------------------------------------------------------

if ! gpg --batch --quiet --list-secret-keys "${KEY_FINGERPRINT}" > /dev/null 2>&1; then
    echo "error: secret key not found:" >&2
    echo "  ${KEY_FINGERPRINT}" >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Retrieve passphrase from macOS Keychain
# ----------------------------------------------------------------------------

KEYCHAIN_PASSWORD=""

if ! KEYCHAIN_PASSWORD="$(
    security find-generic-password \
        -s "${KEYCHAIN_SERVICE}" \
        -a "${KEYCHAIN_ACCOUNT}" \
        -w
)"; then
    echo "error: failed to retrieve GPG passphrase from macOS Keychain." >&2
    exit 1
fi

if [[ -z "${KEYCHAIN_PASSWORD}" ]]; then
    echo "error: Keychain returned an empty GPG passphrase." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Create temporary files
# ----------------------------------------------------------------------------

TMP_PUBLIC="$(mktemp "${BACKUP_DIR}/.public_key.asc.XXXXXX")"
TMP_PRIVATE="$(mktemp "${BACKUP_DIR}/.private_key.asc.XXXXXX")"

chmod 600 "${TMP_PUBLIC}" "${TMP_PRIVATE}"

# ----------------------------------------------------------------------------
# Export public key
# ----------------------------------------------------------------------------

if ! gpg \
    --batch \
    --armor \
    --export \
    "${KEY_FINGERPRINT}" \
    > "${TMP_PUBLIC}"; then
    echo "error: failed to export public key." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Export secret key
#
# IMPORTANT:
#   The passphrase is supplied through file descriptor 3
# ----------------------------------------------------------------------------

if ! gpg \
    --batch \
    --pinentry-mode loopback \
    --passphrase-fd 3 \
    --armor \
    --export-secret-keys \
    "${KEY_FINGERPRINT}" \
    3<<< "${KEYCHAIN_PASSWORD}" \
    > "${TMP_PRIVATE}"; then
    echo "error: failed to export secret key." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Clear the shell variable as soon as possible.
#
# This is not a cryptographic guarantee that every copy is erased from
# process memory, but it reduces the lifetime of the plaintext passphrase
# in this shell.
# ----------------------------------------------------------------------------

KEYCHAIN_PASSWORD=""

# ----------------------------------------------------------------------------
# Basic sanity checks
# ----------------------------------------------------------------------------

if [[ ! -s "${TMP_PUBLIC}" ]]; then
    echo "error: exported public-key file is empty." >&2
    exit 1
fi

if [[ ! -s "${TMP_PRIVATE}" ]]; then
    echo "error: exported private-key file is empty." >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Verify that the exported secret-key file contains the expected key.
# ----------------------------------------------------------------------------

EXPORTED_FINGERPRINT="$(
    gpg \
        --batch \
        --with-colons \
        --import-options show-only \
        --import "${TMP_PRIVATE}" 2> /dev/null |
        awk -F: '
            $1 == "fpr" {
                print $10
                exit
            }
        '
)"

if [[ "${EXPORTED_FINGERPRINT}" != "${KEY_FINGERPRINT}" ]]; then
    echo "error: exported secret key fingerprint does not match target key." >&2
    echo "expected: ${KEY_FINGERPRINT}" >&2
    echo "actual:   ${EXPORTED_FINGERPRINT:-<none>}" >&2
    exit 1
fi

# ----------------------------------------------------------------------------
# Install final files atomically.
# ----------------------------------------------------------------------------

chmod 600 "${TMP_PRIVATE}"
chmod 600 "${TMP_PUBLIC}"

mv -f -- "${TMP_PUBLIC}" "${PUBLIC_KEY_FILE}"
TMP_PUBLIC=""

mv -f -- "${TMP_PRIVATE}" "${PRIVATE_KEY_FILE}"
TMP_PRIVATE=""

# ----------------------------------------------------------------------------
# Final information
# ----------------------------------------------------------------------------

echo "GPG key backup completed successfully."
echo "Public key:"
echo "  ${PUBLIC_KEY_FILE}"
echo
echo "Private key:"
echo "  ${PRIVATE_KEY_FILE}"
