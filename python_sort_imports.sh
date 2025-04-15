#!/usr/bin/env bash

#=python
#@sort import statements of python
#@usage:
#@注意:没有递归
#@一个脚本文件:
#@sort_python_import.sh source.py
#@多个脚本文件:
#@sort_python_import.sh source1.py source2.py ...
#@当前目录:
#@sort_python_import.sh
#@当前目录:
#@sort_python_import.sh .
#@其它目录:
#@sort_python_import.sh dir

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "一个脚本文件:"
    echo "${script} source.py"
    echo "多个脚本文件:"
    echo "${script} source1.py source2.py ..."
    echo "当前目录:"
    echo "${script}"
    echo "当前目录:"
    echo "${script} ."
    echo "其它目录:"
    echo "${script} dir"

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

main() {
    process_opts "${@}"
    shift $((OPTIND - 1))

    #如果在命令行参数中忽略了表示当前目录的.
    #那么在这里给加上
    if (($# == 0)); then
        set -- .
    fi

    #根据命令行参数来收集文件
    files=()
    for arg in "${@}"; do
        #如果是python脚本文件的话
        if [ -f "${arg}" ]; then
            #获取后缀名
            suffix="${arg##*.}"
            if [[ "${suffix}" = 'py' ]]; then
                files+=("${arg}")
            fi
        elif [ -d "${arg}" ]; then
            files_in_dir=()
            #使用fd命令来查找该目录下的所有python文件(--extension py),并将找到的文件添加到files数组中
            #--exact-depth 1:没有递归目录
            #注意:这里不要用双引号把${recursive},${extension}给括起来
            mapfile -t files_in_dir < <(fd --exact-depth 1 --type f --extension py --glob '*' "${arg}")
            files+=("${files_in_dir[@]}")
        fi
    done

    for file in "${files[@]}"; do
        #isort是一个python文件的导入排序工具,--only-modified表示只格式化修改过的部分
        isort --only-modified --quiet "${file}"

        #s/^\s+$//:将只包含空白字符的行替换为空
        #/^$/N:匹配空行,并读取下一行
        #/^\n$/D:删除连续的空行
        sed -i -r 's/^\s+$//' "${file}" && sed -i '/^$/N;/^\n$/D' "${file}"
    done
}

main "${@}"
