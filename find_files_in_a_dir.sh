#!/usr/bin/env bash

#=tools
#@查找文件
#@包含隐藏文件,不区分大小写
#@可以指定后缀名,关键字
#@可以指定忽略项(用逗号分割,逗号两边不能有空格)
#@支持递归
#@usage:
#@script.sh -h
#@在其它脚本中调用该脚本的方法:
#@while IFS= read -r file; do
#@    echo "${file}"
#@done < <(script.sh -d dir)

usage() {
    cat << EOF
用法:
$(basename "${0}") [-d <目标目录>] [-e <后缀名>] [-k <关键字>] [-r] [-i <忽略文件,忽略子目录,忽略pattern,...>] [--debug]

选项:
    -d       指定目标目录(默认为当前目录)
    -e       指定文件后缀名,例如:".txt" 或 "txt"
    -k       指定文件名关键字
    -r       启用递归
    -i       忽略项,使用逗号分隔(注意:被忽略的文件仅填写其basename即可,不能写成包含路径的fullname)
    -h       显示此帮助信息
    --debug  仅打印命令,不执行

示例:
    $(basename "${0}") -d . -e .go -i vendor,node_modules
    $(basename "${0}") -d /tmp -k log -r
    $(basename "${0}") -k test -e .go --debug
EOF
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
}

main() {
    REQUIRED_TOOLS=("fd")
    check_dependent_tools "${REQUIRED_TOOLS[@]}"

    DIR="."
    EXT=""
    KEYWORD=""
    RECURSIVE=false
    IGNORE_DIRS=()
    DEBUG=false

    #getopts无法解析长选项--debug,因此手动处理
    ARGS=()
    for arg in "$@"; do
        if [[ "$arg" == "--debug" ]]; then
            DEBUG=true
        else
            ARGS+=("$arg")
        fi
    done

    #重新设置位置参数
    set -- "${ARGS[@]}"

    while getopts "d:e:k:ri:h" opt; do
        case $opt in
            d) DIR="$OPTARG" ;;
            e) EXT="$OPTARG" ;;
            k) KEYWORD="$OPTARG" ;;
            r) RECURSIVE=true ;;
            i) IFS=',' read -r -a IGNORE_DIRS <<< "$OPTARG" ;;
            h) usage ;;
            *) usage ;;
        esac
    done

    if [[ ! -d "$DIR" ]]; then
        echo "错误:目录不存在:$DIR" >&2
        exit 1
    fi

    #如果没有点,就自动补上一个点
    #.*在[[ ... ]]内表示"以.开头的任意字符串"
    if [[ -n "$EXT" && "$EXT" != .* ]]; then
        EXT=".$EXT"
    fi

    #构造fd命令
    #"":空pattern(占位符)
    fd_cmd=(fd "" "$DIR")

    #显示隐藏文件
    fd_cmd+=(--hidden)

    #不区分大小写
    fd_cmd+=(--ignore-case)

    #控制递归深度
    if ! $RECURSIVE; then
        fd_cmd+=(-d 1)
    fi

    #忽略项
    for ignore in "${IGNORE_DIRS[@]}"; do
        fd_cmd+=(--exclude "$ignore")
    done

    #替换pattern占位符
    if [[ -n "$EXT" && -n "$KEYWORD" ]]; then
        fd_cmd[1]="(${KEYWORD}.*${EXT}|${EXT}.*${KEYWORD})"
    elif [[ -n "$EXT" ]]; then
        fd_cmd[1]="$EXT$"
    elif [[ -n "$KEYWORD" ]]; then
        fd_cmd[1]="$KEYWORD"
    else
        #匹配全部
        fd_cmd[1]=""
    fi

    #限定文件类型
    fd_cmd+=(--type f)

    #输出或执行
    if $DEBUG; then
        echo "命令未执行:"
        printf '  %q' "${fd_cmd[@]}"
    else
        #echo "执行命令:" "${fd_cmd[@]}"
        "${fd_cmd[@]}"
    fi
}

main "${@}"
