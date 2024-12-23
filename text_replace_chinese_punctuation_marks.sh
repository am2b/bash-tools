#!/usr/bin/env bash

#=text
#@replace chinese punctuation marks

#@usage:
#@一个文件:
#@replace_punctuation_marks.sh file
#@多个文件:
#@replace_punctuation_marks.sh file1 file2 ...
#@当前目录:
#@replace_punctuation_marks.sh
#@当前目录:
#@replace_punctuation_marks.sh .
#@其它目录:
#@replace_punctuation_marks.sh dir

#递归:
#-r
#扩展名:
#-e

#0:false
opt_r=0
opt_e=''

optstring=':re:'

while getopts "${optstring}" opt; do
    case "${opt}" in
        r)
            #1:true
            opt_r=1
            ;;
        e)
            opt_e=$OPTARG
            ;;
    esac
done

shift $((OPTIND - 1))

#如果在命令行参数中忽略了表示当前目录的.
#那么在这里给加上
if (( $# == 0 )); then
    set -- .
fi

#根据命令行选项和参数来收集文件
files=()
for arg in "${@}"; do
    #如果是文件的话,就忽略-r和-e选项
    if [ -f "${arg}" ]; then
        files+=("${arg}")
    elif [ -d "${arg}" ]; then
        #0:false
        if (( "${opt_r}" == 0 )); then
            recursive='--exact-depth 1'
        else
            recursive=''
        fi

        if [[ -n "${opt_e}" ]]; then
            extension="--extension ${opt_e}"
        fi

        files_in_dir=()
        #注意:这里不要用双引号把${recursive},${extension}给括起来
        mapfile -t files_in_dir < <(fd ${recursive} --type f ${extension} --glob '*' "${arg}")
        files+=("${files_in_dir[@]}")
    fi
done

#遍历收集的文件
for file in "${files[@]}"; do
    #跳过自己
    if [[ $(basename "${file}") = $(basename "${0}") ]]; then
        continue
    fi

    #没有替换句号
    sed -i -e 'y/！（）：；，？/!():;,?/' -e 'y/“/"/' -e 'y/”/"/' -e "y/‘/'/" -e "y/’/'/" "${file}"
done
