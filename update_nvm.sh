#!/usr/bin/env bash

set -e

#=node
#@update nvm
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script" >&2
    exit "${1:-1}"
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage 0
            ;;
        *)
            echo "error:unsupported option -$opt" >&2
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    NVM_DIR="$HOME/.config/nvm"
    NVM_REPO="https://github.com/nvm-sh/nvm.git"

    #获取远程最新版本号
    latest_version=$(git ls-remote --tags "$NVM_REPO" |
        grep -o 'refs/tags/v[0-9]*\.[0-9]*\.[0-9]*$' |
        sed 's#refs/tags/##' |
        sort -V |
        tail -n 1)

    #获取本地nvm版本号
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        #加载nvm环境
        source "$NVM_DIR/nvm.sh"
        current_version=$(nvm --version 2>/dev/null | sed 's/^v//')
        current_version="v$current_version"
    else
        echo "nvm未安装或未配置,准备安装最新版:$latest_version"
        current_version="none"
    fi

    echo "当前版本:$current_version"
    echo "最新版本:$latest_version"

    #比较版本并更新
    if [ "$current_version" != "$latest_version" ]; then
        echo "更新nvm到$latest_version ..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/"$latest_version"/install.sh | bash
        echo "nvm已更新到$latest_version,请重新打开终端或运行以下命令以生效:"
        echo "source ~/.nvm/nvm.sh"
    else
        echo "nvm已是最新版本,无需更新"
    fi

}

main "${@}"
