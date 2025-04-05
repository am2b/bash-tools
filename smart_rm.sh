#!/usr/bin/env bash

#=tools
#@smart rm

TRASH_DIR="$HOME/.trash"

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script <file_or_directory1> <file_or_directory2> ..."
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
    if (("$#" == 0)); then
        usage
    fi
}

#检查目标是否在Git的管理之下
is_git_tracked() {
    #检查是否在Git仓库中
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        return 1
    fi

    git ls-files --error-unmatch "$1" >/dev/null 2>&1
    return $?
}

move_to_trash() {
    local item="$1"

    #获取文件所在目录和文件名
    local dir_name
    local base_name
    dir_name=$(dirname "$item")
    base_name=$(basename "$item")

    #获取文件名和扩展名
    local file_name="${base_name%%.*}"
    local extension="${base_name#*.}"
    #如果没有扩展名
    if [[ "${file_name}" == "${base_name}" ]]; then
        extension=""
    fi

    #检查是否文件已存在于回收站
    if [[ -e "${TRASH_DIR}/${base_name}" ]]; then
        # 生成时间戳并构造新文件名
        local timestamp
        timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
        local new_item

        if [[ -f "${item}" ]]; then
            new_item="${dir_name}/${file_name}_${timestamp}.${extension}"
        elif [[ -d "${item}" ]]; then
            new_item="${dir_name}/${file_name}_${timestamp}"
        fi

        #重命名文件
        mv "${item}" "${new_item}" || {
            echo "error:移动失败:$item"
            exit 1
        }
        item="${new_item}"
    fi

    #将文件移动到回收站目录
    #mv "$item" "$TRASH_DIR"
    trash "${item}" || {
        echo "error:删除失败:$item"
        exit 1
    }
}

#处理文件或目录
delete_item() {
    local item="$1"

    if [[ ! -e "$item" ]]; then
        echo "error:'$item' 不存在"
        return
    fi

    if is_git_tracked "$item"; then
        #如果是目录,使用-r
        if [[ -d "$item" ]]; then
            git rm -r --cached "$item" >/dev/null 2>&1 || { echo "error:git rm失败"; exit 1;}
        else
            git rm --cached "$item" >/dev/null 2>&1 || { echo "error:git rm失败"; exit 1;}
        fi

        #询问用户是否从文件系统中删除(因为上面的git rm命令使用了--cached选项)
        read -r -n 1 -p "是否要从文件系统中删除 '$item'？[Y]es " answer
        echo
        case "$answer" in
        [yY] | "") # y/Y 或者 Enter
            # 移动到 ~/.trash
            move_to_trash "${item}"
            ;;
        *) # 其它输入
            echo "未从文件系统中删除 '$item'。"
            ;;
        esac
    else
        #如果正在删除的文件或目录还未被git管理(还未git add),那么是会走这里的
        #如果是软链接的话
        if [[ -L "${item}" ]]; then
            rm "${item}" || {
                echo "error:删除软链接失败:$item"
                exit 1
            }
        else
            #移动到~/.trash
            move_to_trash "${item}"
        fi
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    if ! command -v trash &>/dev/null; then
        echo "this script uses the \"trash\" command"
        exit 1
    fi

    #如果不是macOS的话
    if [[ "$(uname)" != "Darwin" ]]; then
        #!运算符用于否定条件
        #使用双引号包裹变量可以避免路径中有空格或特殊字符时出现问题
        if [[ ! -d "${TRASH_DIR}" ]]; then
            mkdir -p "${TRASH_DIR}" || {
                echo "error:无法创建回收站目录"
                exit 1
            }
        fi
    fi

    for item in "$@"; do
        delete_item "$item"
    done
}

main "${@}"
