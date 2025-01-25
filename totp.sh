#!/usr/bin/env bash

#=password
#@generate totp(Time-Based One-Time Password)
#@usage:
#@totp.sh "totp_uri"

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script \"totp_uri\""
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

check_dependent_tools() {
    if ! command -v oathtool &>/dev/null; then
        echo "error:'oathtool' is required but not installed"
        echo "brew install oath-toolkit"
        exit 1
    fi
}

generate_totp() {
    local totp_uri="${1}"

    #提取secret的值(通常使用Base32编码)(label和issuer仅用于标识服务,不影响TOTP的计算)
    if [[ $totp_uri =~ secret=([^&]+) ]]; then
        local secret="${BASH_REMATCH[1]}"
        #生成一次性密码
        oathtool --base32 --totp "${secret}"
    else
        echo "error:invalid totp uri"
        return 1
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    check_dependent_tools

    local totp_uri="${1}"
    otp=$(generate_totp "${totp_uri}")
    echo "${otp}"
}

main "${@}"
