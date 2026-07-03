#!/usr/bin/env bash

#=git-clone
#@在当前目录clone远程仓库,但是只拉取指定数字的深度

build_github_url() {
    local url="$1"
    local prefix="https://github.com/"
    local spec
    local suffix=".git"

    # 转换ssh URL为https URL
    if [[ "$url" =~ ^git@github\.com:(.+)$ ]]; then
        spec="${BASH_REMATCH[1]}"
    elif [[ "$url" =~ ^https://github\.com/(.+)$ ]]; then
        spec="${BASH_REMATCH[1]}"
    else
        spec="$url"
    fi

    # 去掉可能存在的.git后缀
    spec="${spec%.git}"

    # 如果输入没有用户名,则使用GITHUB_USERNAME环境变量补全
    if [[ "$spec" != */* ]]; then
        if [[ -z "$GITHUB_USERNAME" ]]; then
            echo "Error: GITHUB_USERNAME environment variable is not set." >&2
            return 1
        fi
        spec="$GITHUB_USERNAME/$spec"
    fi

    # 构建最终URL
    echo "${prefix}${spec}${suffix}"
}

script=$(basename "$0")
arrow="--->"
usage="clone the repository into current directory"
usage() {
    echo "Usage:"
    echo "${script}" depth repos "${arrow}" "${usage}"
    echo "${script}" depth owner/repos "${arrow}" "${usage}"
    echo "${script}" depth url "${arrow}" "${usage}"
    exit 1
}

if [[ "$1" == "-h" || $# -ne 2 ]]; then
    usage
fi

url=$(build_github_url "${1}")

git clone --depth "${2}" "${url}"
