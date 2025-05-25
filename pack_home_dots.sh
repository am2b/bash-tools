#!/usr/bin/env bash

#=pack
#@打包HOME目录下的一些隐藏文件
#@usage:
#@nohup script.sh > /tmp/pack_home_dots.log 2>&1 &

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
    if (("$#" != 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    #保存的位置
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    local save_dir="${HOME}/save-home-dots-${TIMESTAMP}"
    mkdir -p "${save_dir}"
    #如果目录非空,则清空
    #if [[ -n "$(find "$save_dir" -mindepth 1 -print -quit)" ]]; then
    #    find "$save_dir" -mindepth 1 -exec rm -rf {} +
    #fi

    #要保存的目录和文件
    local -a dirs=(.am2b .config .gnupg .key-ring .local .private .tag .tube-top)
    local -a files=(.bashrc .msmtprc .password .one_key_move)

    #进入~
    cd ~ || exit 1

    #打包
    local pack_name

    #分别打包每个目录
    for dir in "${dirs[@]}"; do
        #如果目录不存在
        if ! [ -d "${dir}" ]; then
            continue
        fi

        #如果目录是空的
        #-mindepth 1:忽略自身
        #-print -quit:一旦找到一个内容就退出(高效)
        #-z:如果find没有输出,则说明目录是空的
        if [[ -z $(find "$dir" -mindepth 1 -print -quit) ]]; then
            continue
        fi

        pack_name="${dir#.}.tar.gz"
        #排除socket和.lock文件
        #--null:告诉tar以null字符分隔读取文件名
        #--no-recursion:禁用默认递归
        #-T -:告诉tar从标准输入读取文件列表
        find "${dir}" ! -type s ! -name '*.lock' -print0 | tar --null -czf "${pack_name}" --no-recursion -T -
        mv "${pack_name}" "${save_dir}"
    done

    #整体打包所有的文件
    pack_name=files.tar.gz
    #以防止有的文件不存在了
    declare -a real_files
    for file in "${files[@]}"; do
        if ! [ -f "${file}" ]; then
            continue
        fi
        real_files+=("${file}")
    done
    tar -czf "${pack_name}" "${real_files[@]}"
    mv "${pack_name}" "${save_dir}"

    #密码
    local password
    if ! password=$(security find-generic-password -s "7z" -a "save-home-dots" -w 2>/dev/null); then
        echo "error: failed to retrieve password from keychain" >&2
        exit 1
    fi

    cd "${save_dir}" || exit 1

    local base_name
    local pack_name
    while IFS= read -r -d '' file; do
        #移除./
        base_name=$(basename "${file}")
        TIMESTAMP=$(date +"%Y-%m-%d")
        pack_name="${base_name%%.*}-${TIMESTAMP}.7z"
        if ! 7z a -p"${password}" -mhe=on -mx=0 "${pack_name}" "${base_name}" &>/dev/null; then
            echo "打包失败:${pack_name}" >&2
            exit 1
        fi
    done < <(find . -type f ! -name '.DS_Store' -print0)

    rm -rf ./*.tar.gz

    #离开${save_dir}
    cd ~ || exit 1

    #移动${save_dir}至iCloud
    local dest_dir
    dest_dir="${ICLOUD_PATH}"/Home-dots
    mkdir -p "${dest_dir}"
    mv "${save_dir}" "${dest_dir}"

    #进入iCloud目录
    cd "${dest_dir}" || exit 1

    #查找子目录,按修改时间排序(最旧的在前)
    #-printf是GNU find特有的选项,用来自定义输出格式,macOS的find默认不支持-printf
    #%T@:表示文件或目录的最后修改时间,格式为"自unix纪元以来的秒数"(即一个浮点数)
    #%p:表示文件的完整路径
    local subdirs=()
    subdirs=($(find . -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -n | awk '{print $2}'))
    #获取子目录数量
    count=${#subdirs[@]}

    #如果数量超过num,就删除最旧的
    local num=5
    if ((count > num)); then
        local to_delete_num=$((count - num))
        for ((i = 0; i < to_delete_num; i++)); do
            #echo "删除:$(basename "${subdirs[i]}")"
            #trash命令无法用于iCloud
            rm -rf -- "${subdirs[i]}"
        done
    fi

    osascript -e 'display notification "备份home dots的任务已完成" with title "备份home dots" sound name "Glass"'
}

main "${@}"
