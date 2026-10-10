#!/usr/bin/env bash

#=gpg
#@使用gpg加密,解密某个文件
#@usage:
#@encrypt:
#@script.sh -e file
#@decrypt:
#@script.sh -d file.gpg

set -euo pipefail

usage() {
    local script
    script=$(basename "$0")
    cat >&2 << EOF
使用 GPG 公钥加密/解密文件。

加密: 用公钥加密,生成 <原文件>.gpg
解密: 用私钥解密,输出 <文件> 去掉 .gpg 后缀

用法:
  $script -e <文件>        加密
  $script -d <文件.gpg>    解密

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
        echo "error: 需要一个文件参数" >&2
        usage 1
    fi

    local file="$1"

    if [[ -z "${MAIL_GMAIL_MAIN:-}" ]]; then
        echo "error: 需要设置环境变量 MAIL_GMAIL_MAIN" >&2
        exit 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "error: 文件不存在或不是普通文件: $file" >&2
        exit 1
    fi

    if [[ "$mode" == "encrypt" ]]; then
        # 公钥加密
        if gpg --batch --yes --encrypt --recipient "$MAIL_GMAIL_MAIN" "$file"; then
            echo "加密成功: ${file}.gpg"
        else
            echo "error: 加密失败(公钥是否已导入?)" >&2
            exit 1
        fi
    else
        # 私钥解密
        if [[ "$file" != *.gpg ]]; then
            echo "error: 输入文件应以 .gpg 结尾: $file" >&2
            exit 1
        fi

        local output="${file%.gpg}"
        if [[ -e "$output" ]]; then
            echo "error: 输出文件已存在,为避免覆盖已停止: $output" >&2
            exit 1
        fi

        local passphrase
        if ! passphrase=$(security find-generic-password -s "gpg" -a "$MAIL_GMAIL_MAIN" -w 2> /dev/null); then
            echo "error: 无法从钥匙串获取私钥密码" >&2
            exit 1
        fi

        local tmp="${output}.tmp.$$"
        if ! gpg --quiet --batch --pinentry-mode loopback --passphrase-fd 3 --decrypt "$file" 3<<< "$passphrase" > "$tmp" 2> /dev/null; then
            rm -f "$tmp"
            echo "error: 解密失败(密码错误或文件损坏?)" >&2
            exit 1
        fi
        mv "$tmp" "$output"
        echo "解密成功: $output"
    fi
}

main "$@"
