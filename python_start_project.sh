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

insert_enter_point() {
    local name="${1}"
    local file="pyproject.toml"
    local temp_file=$(mktemp)

    #标记是否找到[tool.poetry]
    local found_poetry=false

    #标记是否插入了[tool.poetry.scripts]
    local inserted_scripts=false

    #逐行读取pyproject.toml并修改
    while IFS= read -r line; do
        if [[ $line == "[tool.poetry]" ]]; then
            #若当前行是[tool.poetry],就把found_poetry标记设为true,同时将该行写入临时文件
            found_poetry=true
            echo "$line" >>"$temp_file"
        elif $found_poetry && [[ -z $line ]] && ! $inserted_scripts; then
            #当已经找到[tool.poetry],当前行是空行,并且还未插入[tool.poetry.scripts]时,执行以下操作:
            #写入一个空行
            #写入[tool.poetry.scripts]
            #写入cli = "name_value.main:run",这里的name_value是之前读取到的name值
            #再写入一个空行
            #把inserted_scripts标记设为true
            echo "" >>"$temp_file"
            echo "[tool.poetry.scripts]" >>"$temp_file"
            echo "cli = \"$name.main:run\"" >>"$temp_file"
            echo "" >>"$temp_file"
            inserted_scripts=true
        else
            #若不满足上述条件,就将当前行直接写入临时文件
            echo "$line" >>"$temp_file"
        fi
    done <"$file"

    # 将临时文件内容覆盖原文件
    mv "$temp_file" "$file"
}

insert_custom_info() {
    local file="pyproject.toml"
    local info="${1}"

    echo >> "${file}"
    echo "[custom-info]" >> "${file}"
    echo "${info}" >> "${file}"
}

touch_main() {
    project_name="${1}"

    cat <<EOF >"src/${project_name}/main.py"
def run():
    pass

if __name__ == "__main__":
    run()
EOF
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

    #插入命令行入口
    insert_enter_point "${project_name}"

    #插入个性化信息
    insert_custom_info 'how_to_run = "bash script"'

    #合并pyproject.toml中连续的空行
    sed -i '/^$/N;/^\n$/D' pyproject.toml

    #生成.python-version文件
    pyenv local "${python_version}"
    #读取.python-version,然后修改pyproject.toml里面的python版本
    poetry_modify_python_version.sh
    #指定python解释权,同时也会创建虚拟环境
    poetry env use python
    #创建.envrc文件
    poetry_create_envrc.sh
    direnv allow

    #安装autopep8,pycodestyle
    poetry add --dev autopep8

    python_create_gitignore.sh
    create_LICENSE_MIT.sh am2b

    touch_main "${project_name}"
}

main "${@}"
