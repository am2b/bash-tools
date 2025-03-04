#!/usr/bin/env bash

#=python
#@sort import statements of python

#@usage:
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
        #注意:这里不要用双引号把${recursive},${extension}给括起来
        #--exact-depth:没有递归目录
        mapfile -t files_in_dir < <(fd --exact-depth 1 --type f --extension py --glob '*' "${arg}")
        files+=("${files_in_dir[@]}")
    fi
done

for file in "${files[@]}"; do
    isort --only-modified --quiet "${file}"

    #s/^\s+$//:将只包含空白字符的行替换为空
    #/^$/N:匹配空行,并读取下一行
    #/^\n$/D:删除连续的空行
    sed -i -r 's/^\s+$//' "${file}" && sed -i '/^$/N;/^\n$/D' "${file}"
done
