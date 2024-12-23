#!/usr/bin/env bash

#=text
#@创建或者以只读模式打开一个加密的文本文件
#@usage:
#@script.sh encrypted_text_file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script encrypted_text_file"
    exit 0
}

while getopts "h" opt; do
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
shift $((OPTIND - 1))

if (("$#" != 1)); then
    usage
fi

#检查vim是否存在
if ! command -v vim &>/dev/null; then
    echo "error:vim is not installed"
    echo "You can install it using Homebrew with the following command:brew install vim"
    exit 1
fi

#设置vim为编辑器
EDITOR=$(command -v vim)

#检查是否支持加密
if ! "$EDITOR" --version | grep -q "+cryptv"; then
    echo "error:Your $EDITOR does not support encryption (missing +cryptv)."
    exit 1
fi

#创建临时文件用于测试
#TMPFILE=$(mktemp)
#echo "test file for encryption check" >"$TMPFILE"

#检查当前加密方法
#-E:启动Vim的Ex模式,只执行命令,不进入完整的编辑界面
#-s:启动Vim的静默模式,抑制不必要的输出,避免用户干预
#<<EOF...EOF
#这里使用HereDocument向Vim提供多行输入命令
#<<EOF指定了一个输入块,直到EOF行结束,块中的命令将被传递给Vim执行
#CRYPT_METHOD=$(
#    "$EDITOR" -E -s "$TMPFILE" <<EOF
#:set cryptmethod?
#:quit
#EOF
#)

#清理临时文件
#rm -f "$TMPFILE"

#提取加密方法
#-o:只输出匹配到的内容
#-P:启用Perl正则表达式
#default_method=$(echo "$CRYPT_METHOD" | grep -oP '(?<=cryptmethod=)\w+')

#注意:其实vim默认的加密方式就是:blowfish2
#if [[ "$default_method" != "blowfish2" ]]; then
#    echo "Warning:Your $EDITOR encryption method is not blowfish2 (current:$default_method)"
#    exit 1
#fi

if [[ ! -d $HOME/.vim ]]; then
    mkdir -p "${HOME}"/.vim
fi

if [[ ! -f $HOME/.vim/vimencrypt ]]; then
    cat <<EOF >"${HOME}"/.vim/vimencrypt
"usage:
"vim -u ~/.vim/vimencrypt -x <file>

set viminfo=
set nobackup
set noswapfile
set nowritebackup
EOF
fi

file="${1}"

#创建or以只读模式打开
if [[ -f "${file}" ]]; then
    vim -u "${HOME}"/.vim/vimencrypt -R "${file}"
else
    vim -u "${HOME}"/.vim/vimencrypt -x "${1}"
fi

#set viminfo=:
#viminfo用于记录Vim的会话历史,如搜索历史,寄存器内容,命令历史等
#set nobackup:
#这个选项禁用文件备份,在默认情况下,vim 会在修改文件时创建一个备份副本,以防止文件丢失
#set noswapfile:
#这个选项禁用交换文件(swapfile),交换文件是vim用来保存未保存内容的临时文件,当vim异常退出时,它可以帮助恢复编辑内容
#set nowritebackup:
#这个选项禁用写时备份(write backup),当你在文件上进行写操作时,vim 会在保存之前创建一个备份副本,以防万一发生问题。
