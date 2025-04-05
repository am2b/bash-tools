#!/usr/bin/env bash

#=tools
#@smart mv

#控制是否启用调试信息
DEBUG_MODE=true

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script <source1> <source2> ... <destination>"
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
    if (("$#" < 2)); then
        usage
    fi
}

debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo "debug:" "$@" >&2
    fi
}

#git ls-files:
#这是Git的一个命令,用于列出当前Git仓库中被跟踪的文件
#它会返回所有已添加到索引中的文件,并且可以使用不同的选项进行过滤和格式化输出

#--error-unmatch "$1":
#--error-unmatch 选项用于检测特定文件是否在Git的版本控制中
#"$1"是一个位置参数,通常是传递给脚本或函数的第一个参数。在这个上下文中,它代表你想要检查的文件名或路径
#如果该文件或目录没有被跟踪,git ls-files --error-unmatch "$1" 会返回一个错误,返回值为1(非零表示错误),否则就返回0

#>/dev/null:
#这是将标准输出重定向到/dev/null,即丢弃标准输出
#2>&1:
#这部分将标准错误(文件描述符2)重定向到标准输出(文件描述符1)
#由于标准输出已经被重定向到/dev/null,这将意味着所有的错误信息也会被丢弃
#这样,执行命令后,用户不会看到任何错误信息

#检查文件或目录是否在Git仓库管理下
#参数:文件或目录
is_git_tracked() {
    git ls-files --error-unmatch "$1" >/dev/null 2>&1
    return $?
}

#git -C "$dir":
#-C 用于在执行命令之前切换到指定的目录,这个选项可以让你在不改变当前工作目录的情况下,在指定目录执行Git命令
#git -C选项期望的是一个目录,而不是一个文件名,要获取某个文件所属的Git仓库的根目录,你需要给git -C提供文件所在的目录,而不是文件本身,具体来说,git -C应该指向文件的父目录
#"$dir" 是你传递的一个目录,表示你想要在这个目录下运行后续的Git命令
#"$dir" 可能是绝对路径或相对路径

#rev-parse --show-toplevel:
#rev-parse 是一个Git命令,用于解析Git的内部对象(如分支、提交哈希等),也可以用于检索一些Git仓库相关的信息
#--show-toplevel是rev-parse的一个选项,专门用于显示当前Git仓库的顶级目录(也就是.git文件夹所在的目录)

#当你在一个Git仓库中的任意子目录下执行git rev-parse --show-toplevel,Git会向上查找,直到找到.git目录,这个路径即为仓库的根目录
#如果指定目录($dir)不在一个Git仓库内,git rev-parse --show-toplevel会返回一个错误消息,比如fatal:not a git repository,但由于我们将错误输出重定向到了/dev/null,这些错误信息不会显示在终端中

#获取source/dest所属的Git仓库的根目录,返回根目录路径；如果路径不在Git仓库内,返回空字符串
get_git_root() {
    local dir

    if is_dir "${1}"; then
        dir="${1}"
    else
        dir=$(dirname "${1}")
    fi

    git -C "$dir" rev-parse --show-toplevel 2>/dev/null
}

#要判断source和dest是否在同一个Git仓库内,可以通过检查它们各自的Git根目录是否相同
is_same_git_repo() {
    local source_git_root
    local dest_git_root

    source_git_root=$(get_git_root "$1")
    dest_git_root=$(get_git_root "$2")

    if [[ -n "$source_git_root" && "$source_git_root" == "$dest_git_root" ]]; then
        return 0 #同一个仓库
    else
        return 1 #不同的仓库
    fi
}

#是否看上去像目录:以"/"结尾
looks_like_dir() {
    local dest="$1"
    if [[ "$dest" == */ && ! -d "$dest" ]]; then
        return 0 #像
    else
        return 1 #不像
    fi
}

#创建目录
create_dir() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}" || {
            echo "Error:无法创建目标目录'${dir}'"
            exit 1
        }
    fi
}

#是否存在
is_exist() {
    if [[ -e "${1}" ]]; then
        return 0
    else
        return 1
    fi
}

#是文件
is_file() {
    if [[ -f "${1}" ]]; then
        return 0
    else
        return 1
    fi
}

#是目录
is_dir() {
    if [[ -d "${1}" ]]; then
        return 0
    else
        return 1
    fi
}

#处理文件或目录移动
move_item() {
    local source="$1"
    local dest="$2"

    #如果source是在Git管理下
    if is_git_tracked "$source"; then
        #判断source和dest是否属于同一个Git仓库
        if is_same_git_repo "$source" "$dest"; then
            #同一个Git仓库,使用git mv
            git mv "$source" "$dest"
        else
            #dest不是source所在的Git仓库
            cp -r "$source" "$dest"
            git rm -r "$source" >/dev/null
        fi
    else
        #如果source是在一个普通目录
        mv "$source" "$dest"
    fi
}

main() {
    #参数数量
    local params_count="$#"

    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #拆分参数
    #获取命令行参数中的最后一个参数,不涉及数组展开
    local dest="${!#}"
    local sources=("${@:1:$#-1}")

    #统计bad source的数量
    local bad_sources_count=0
    for source in "${sources[@]}"; do
        if [[ ! -e "${source}" ]]; then
            ((bad_sources_count++))
        fi
    done
    #如果所有的source参数都不存在的话
    if [[ "${bad_sources_count}" -eq "${#sources[@]}" ]]; then
        echo "Error:all sources do not exist."
        exit 1
    fi

    #如果dest看起来像是一个目录的话
    looks_like_dir "${dest}" && create_dir "${dest}"

    #如果有多个source的话,那么dest肯定是一个目录
    if [[ "${params_count}" -gt 2 ]]; then create_dir "${dest}"; fi

    #如果只有一个source,并且dest后面没有/,并且dest也不存在,那么确保dest的父目录存在
    if [[ "${params_count}" -eq 2 ]]; then
        if ! looks_like_dir "${dest}"; then
            if [[ ! -e "${dest}" ]]; then
                local dest_parent
                dest_parent=$(dirname "${dest}")
                create_dir "${dest_parent}"
            fi
        fi
    fi

    #逐个move文件或目录
    for source in "${sources[@]}"; do
        #如果某一个source不存在的话
        if [[ ! -e "${source}" ]]; then
            echo "Error:" "${source}" "does not exist."
            continue
        fi

        move_item "$source" "$dest"
    done
}

main "${@}"
