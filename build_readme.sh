#!/usr/bin/env bash

#=tools
#@在项目根目录运行以构建README.md

readme_file=$(pwd)/README.md
readme_bak_file=$(pwd)/README.md.bak
readme_file_exist=false

cache_file="${BASH_TOOLS_README_CACHE_FILE}"
cache_file_exist=false
#因为cache文件就代表了上一次的README.md.bak文件,所以后面的逻辑如果要使用cache文件话,就必须cache文件和README.md.bak这两个文件都存在,否则就需要遍历读取本地的每一个脚本文件
use_cache=false
declare -A caches

#存储所有脚本的名字
scripts=()

#如果存在缓存文件的话,计算本地文件和缓存文件之间的差异
#新增的脚本
added=()
#修改的脚本
modified=()
#删除的脚本
deleted=()

#scripts_info:收集每个脚本里面的info
#key:脚本的名字
#value:第一行代表类别,其余行代表描述
declare -A scripts_info

#收集所有的类别
categorys=()

check_in_git() {
    if [ ! -d "$(pwd)"/.git ]; then
        echo "Run this script in the root directory of your project"
        exit 1
    fi
}

required_tools() {
    local tools=("sed" "stat" "date")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "$tool 未安装,请安装 GNU Coreutils"
            exit 1
        fi
        if ! "$tool" --version 2>/dev/null | grep -q "GNU"; then
            echo "$tool 不是 GNU Coreutils 版本,请安装正确版本"
            exit 1
        fi
    done
}

backup_readme_file() {
    if [ -f "${readme_file}" ]; then
        readme_file_exist=true
        #如果已经存在README.md文件,那么将其备份
        mv "${readme_file}" "${readme_bak_file}"
        #给末尾追加一个空行
        echo >>"$readme_bak_file"
    fi
}

read_cache_file() {
    if [[ -f $cache_file ]]; then
        cache_file_exist=true
        #读取缓存信息
        while IFS="," read -r script mtime; do
            caches["$script"]=$mtime
        done <"$cache_file"
    fi
}

determine_whether_to_use_cache() {
    if $readme_file_exist && $cache_file_exist; then
        use_cache=true
    fi
}

collect_scripts() {
    #收集所有的脚本文件
    mapfile -t scripts < <(find . -type f -not -path "./.git/*" -not -name "README*" -not -name "LICENSE" -not -name "$(basename "${0}")" | sed 's|^\./||')
    #对scripts排序,以便于使每个类别下的脚本也是有序的(逆序,便于后面往README.md里面插入)
    scripts=($(printf "%s\n" "${scripts[@]}" | sort -r))
}

build_difference_data() {
    if $use_cache; then
        for script in "${scripts[@]}"; do
            if [[ -v caches[$script] ]]; then
                #在cache里面有这个脚本
                mtime=$(stat -c "%Y" "$script")
                if ((mtime != "${caches[$script]}")); then
                    #脚本被修改过
                    modified+=("${script}")
                fi
                #只要cache里面有这个脚本,那么这里把这个脚本从cache里面删除掉,这样等到遍历结束后,cache里面剩下的脚本就是在本地被删除了的脚本
                unset caches["$script"]
            else
                #在cache里面没有这个脚本
                added+=("${script}")
            fi
        done

        for script in "${!caches[@]}"; do
            deleted+=("${script}")
            unset caches["$script"]
        done
    fi
}

read_category_from_script() {
    local script="${1}"
    local cate
    cate=$(sed -n 's/#=//p' "${script}")
    echo "${cate}"
}

read_description_from_script() {
    local script="${1}"
    local desc
    desc=$(sed -n 's/^#@\(.*\)$/\1<br>/p' "${script}")
    desc=$(echo "${desc}" | sed '$s/<br>//')
    echo "${desc}"
}

#如果没有缓存文件的话,那么就需要遍历本地的每个脚本来填充scripts_info
#如果有缓存文件的话,那么scripts_info的内容就可以通过如下方式来构建:
#1,读取上一次的README.md文件来填充scripts_info
#2,遍历added,modified,deleted这三个数组来对scripts_info进行修正
filling_data_into_an_associative_array() {
    if ! $use_cache; then
        #不使用cache文件,遍历本地的每个脚本来填充scripts_info
        for script in "${scripts[@]}"; do
            cate=$(read_category_from_script "${script}")
            desc=$(read_description_from_script "${script}")
            #collect category
            categorys+=("${cate}")
            #add $ operator before \n
            scripts_info["${script}"]="${cate}"$'\n'"${desc}"
        done
    else
        #解析上次的README.md
        while IFS= read -r line; do
            if [[ "$line" =~ ^##[[:space:]](.+):$ ]]; then
                cate="${BASH_REMATCH[1]}"
                #collect category
                categorys+=("${cate}")
            elif [[ "$line" =~ ^###\ \[([^\]]+)\]\([^\)]+\): ]]; then
                script="${BASH_REMATCH[1]}"
                desc=""
                while IFS= read -r line; do
                    if [[ -z "$line" ]]; then
                        break
                    fi
                    desc+="${line}"$'\n'
                done

                scripts_info["$script"]=$(printf "%s\n%s" "$cate" "$desc")
            fi
        done <"$readme_bak_file"

        #接着按顺序处理三个数组:deleted,modified,added
        for script in "${deleted[@]}"; do
            unset "${scripts_info["$script"]}"
        done

        for script in "${modified[@]}"; do
            unset "${scripts_info["$script"]}"
            added+=("${script}")
        done

        for script in "${added[@]}"; do
            cate=$(read_category_from_script "${script}")
            desc=$(read_description_from_script "${script}")
            #collect category
            categorys+=("${cate}")
            scripts_info["$script"]=$(printf "%s\n%s" "$cate" "$desc")
        done
    fi
}

create_readme_file() {
    #对categorys排序,去重
    categorys=($(printf "%s\n" "${categorys[@]}" | sort | uniq))

    #1,先插入类别,每行一个类别,行与行之间添加一个空行
    for cate in "${categorys[@]}"; do
        {
            echo -n "## "
            echo "${cate}:"
        } >>"${readme_file}"
    done
    #2,插入具体的脚本到其类别下
    for script in "${scripts[@]}"; do
        value="${scripts_info["${script}"]}"

        #该脚本所属的类别是value的第一行,value剩余的行是该脚本的描述信息
        cate=$(echo "${value}" | sed -n '1p')
        desc=$(echo "${value}" | sed -n '2,$p')

        link="### [$script]($script):<br>"

        #在README.md中找到该脚本所属的类别,然后将该脚本的link信息和描述信息插入其后
        sed -i "/^## $cate:$/r"<(
            echo "${link}"
            echo "${desc}"
            echo
        ) "${readme_file}"
    done
}

delete_blank_lines_at_the_end() {
    local file="${1}"
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "${file}"
}

do_diff() {
    #如果已经存在README.md文件,那么给出二者的diff
    if $readme_file_exist; then
        #删除末尾的空行
        delete_blank_lines_at_the_end "${readme_bak_file}"

        if ! diff --color=auto --unified "${readme_bak_file}" "${readme_file}"; then
            #提示是否要删除备份
            read -r -n 1 -p "delete ${readme_bak_file}? [Y/n]" delete_bak
            echo
            case "${delete_bak}" in
            'y' | 'Y' | '')
                delete_bak=1
                ;;
            *)
                delete_bak=0
                ;;
            esac

            if (("${delete_bak}" == 1)); then rm "${readme_bak_file}"; fi
        else
            rm "${readme_bak_file}"
        fi
    fi
}

create_cache_file() {
    #清空
    : >"${cache_file}"

    local buffer=()
    for script in "${scripts[@]}"; do
        mtime=$(stat -c "%Y" "$script")
        buffer+=("${script},${mtime}")
    done

    #一次性写入文件
    printf "%s\n" "${buffer[@]}" >"${cache_file}"
}

main() {
    check_in_git

    required_tools

    #备份README.md
    backup_readme_file

    #读取cache file
    read_cache_file

    #决定是否使用cache file
    determine_whether_to_use_cache

    #收集本地的脚本文件
    collect_scripts

    #填充added,modified,deleted这三个数组
    build_difference_data

    #填充数据到一个关联数组
    filling_data_into_an_associative_array

    #生成新的README.md文件
    create_readme_file

    #如果README.md文件,最后有一个空行的话,那么将其删掉
    delete_blank_lines_at_the_end "${readme_file}"

    do_diff

    #生成新的cache
    create_cache_file
}

main
