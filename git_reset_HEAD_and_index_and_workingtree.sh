#!/usr/bin/env bash

#=git-reset
#@重置本地的HEAD到某个提交,然后用该提交来填充index和working tree(回退到工作区被修改之前,注意:工作区所做的修改全部被丢弃了,如果有创建目录,那么目录还在但是被清空了)

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script ---> reset HEAD to HEAD~"
    echo "$script <commit> ---> reset HEAD to <commit>, update the index, and make the working tree look like the index"
}

if [[ "$1" == "-h" || "$#" -gt 1 ]]; then
    usage
    exit 0
fi

cmd="git reset --hard"
if [[ "$#" -eq 0 ]]; then
    cmd="$cmd HEAD~"
else
    cmd="$cmd $1"
fi

# 检查是否从管道输入
if [[ -p /dev/stdin ]]; then
    # 只读取一次输入,忽略后续的多余输入
    response=$(head -n 1 | tr '[:upper:]' '[:lower:]')
else
    #for distinguishing space and enter
    IFS=

    echo "Warning:This operation will discard all uncommitted changes in the working tree!"
    echo "continue? [Y/n]"
    read -r -s -n 1 response
    # 将输入转换为小写
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
fi

if [[ "$response" == "y" || -z "$response" ]]; then
    eval "$cmd"
fi

#--hard:
#--hard标记是reset命令唯一的危险用法,它也是Git会真正地销毁数据的仅有的几个操作之一
#为什么说这是Git真正地销毁了数据?因为上次git commit所提交的那些修改,已经不在working tree里面了
#reset会用HEAD(after reset)指向的快照内容来更新index和working tree
#git reset --hard HEAD~:
#它会撤销上次提交,会把reset之后HEAD所指向的内容复制到index和working tree,也就是说reset后,通过git restore --cached和git restore会显示没有差别
#于是,我们回滚到了修改working tree,git add和git commit的命令执行之前
