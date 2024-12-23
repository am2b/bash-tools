#!/usr/bin/env bash

#=git-push
#@在本地新建了一个仓库,添加了一些提交,然后把这些提交给push到远程的空仓库

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

#在本地通过git init新创建了一个仓库
#在本地仓库做了修改,提交到本地后,需要push该提交到远程仓库
#新建一个远程仓库,新建的时候既没有包含.gitignore文件也没有包含README文件,也没有包含License文件,所以远程仓库是一个空仓库

#所以现在远程仓库和本地仓库的状态是:
#远程仓库为空
#本地仓库非空

script=$(basename "$0")
arrow="--->"
usage="push commits to remote empty repository"
usage() {
    echo "Usage:"
    echo "${script}" repos "${arrow}" "${usage}"
    echo "${script}" owner/repos "${arrow}" "${usage}"
    echo "${script}" url "${arrow}" "${usage}"
    exit 1
}

if [[ "$1" == "-h" || $# -ne 1 ]]; then
    usage
fi

url=$(build_github_url "${1}")

#这样以后就可以在命令行里使用origin来代替$url了
git remote add origin "${url}"
git push --set-upstream origin master
