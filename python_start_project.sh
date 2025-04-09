#!/usr/bin/env bash

#=python
#@在~/repos/目录创建一个被poetry管理的python项目
#@usage:
#@script.sh project_name python_version

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script project_name python_version"
    exit 1
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

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local project_name="${1}"
    local python_version="${2}"

    cd ~/repos || exit 1
    if [[ -d "${project_name}" ]]; then
        echo "项目名称:${project_name} 已经存在了"
        exit 1
    fi

    #pyenvversions --bare:仅输出已安装的版本号(无星号/路径等额外信息)
    #grep -qxF "$version":精确匹配整行内容(-x),且禁用正则表达式(-F)
    if ! pyenv versions --bare | grep -qxF "$python_version"; then
        echo "python版本:${python_version} 没有安装" >&2
        exit 1
    fi

    #创建目录结构,以及pyproject.toml文件(不过还没有创建poetry.lock文件,需要等到poetry add package_name的时候才会创建poetry.lock文件)
    poetry new "${project_name}"

    cd "${project_name}" || exit 1

    #生成.python-version文件
    pyenv local "${python_version}"
    #读取.python-version,然后修改pyproject.toml里面的python版本
    poetry_modify_python_version.sh
    #创建虚拟环境
    poetry env use python
    #创建.envrc文件
    poetry_create_envrc.sh
    direnv allow

    python_create_gitignore.sh
    create_LICENSE_MIT.sh am2b
}

main "${@}"
