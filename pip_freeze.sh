#!/usr/bin/env bash

#=python
#@generate requirements.txt

#如果运行该脚本的路径不正确,则退出
if ! [ -f .envrc ]; then
    exit 1
fi

#获取到所有的.unpip文件名
mapfile -t unpip_files < <(fd --hidden --no-ignore --type f --extension unpip --exec basename)

#移除.unpip文件的后缀名,仅留下包名字
unpip_package_names=()
for f in "${unpip_files[@]}"; do
    #remove extension from filename:"${filename%.*}"
    unpip_package_names+=("${f%.*}")
done

#通过freeze生成一个requirements.txt文件
python -m pip freeze > requirements.txt

#读取requirements.txt文件,每行作为一个元素存放到数组里面
mapfile -t lines < requirements.txt
#遍历unpip_package_names,用每个元素去和lines里面的元素(==前面的部分)进行比较
matched_lines=()
for name in "${unpip_package_names[@]}"; do
    for line in "${lines[@]}"; do
        #取出line==前面的部分
        line_name_part="${line%==*}"
        #然后转换为小写
        line_name_part="${line_name_part,,}"

        if [[ "${name}" = "${line_name_part}" ]]; then
            #注意:这里把requirements里面的每行转换为小写,然后保存
            #因为目前不管包名字是否含有大写字母,我安装的时候都是按照小写字母安装的,生成的.unpip文件名也都是小写
            #如果以后遇到包名字含有大写字母,而无法通过小写来安装的情况的话,就再说
            matched_lines+=("${line,,}")
        fi
    done
done

#对matched_lines排序
matched_lines_sorted=()
IFS=$'\n'
#<<< is a here-string that passes the expanded array as input to sort
mapfile -t matched_lines_sorted < <(sort <<< "${matched_lines[*]}")
unset IFS

#把matched_lines_sorted给写入到requirements.txt中
printf "%s\n" "${matched_lines_sorted[@]}" > requirements.txt
