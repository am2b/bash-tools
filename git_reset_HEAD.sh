#!/usr/bin/env bash

#=git-reset
#@重置本地的HEAD到某个提交(回退到git commit之前,git add之后)

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script ---> reset HEAD to HEAD~"
    echo "$script <commit> ---> reset HEAD to <commit>"
}

if [[ "$1" == "-h" || "$#" -gt 1 ]]; then
    usage
    exit 0
fi

cmd="git reset --soft"
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

    # 非管道输入时提示用户输入
    echo "continue? [Y/n]"
    read -r -s -n 1 response
    # 将输入转换为小写
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
fi

if [[ "$response" == "y" || -z "$response" ]]; then
    eval "$cmd"
fi

#git reset [<mode>] [<commit>]
#resets the current branch head to <commit> and possibly updates the index and the working tree depending on <mode>.if <mode> is omitted,defaults to --mixed.
#--soft:
#resets HEAD to <commit>,but does not touch the index file or the working tree
#--mixed:
#resets HEAD to <commit>,resets the index,but does not touche the working tree
#--hard:
#resets HEAD to <commit>,resets the index and working tree

#reset命令重写的是这三棵树:
#移动HEAD分支的指向(reset moves the branch that HEAD is pointing to)
#使索引看起来像 HEAD
#使工作目录看起来像索引

#git reset --soft HEAD~:
#移动HEAD和指向最后一次提交的分支(比如:master)至最后一次提交的父提交
#效果就是撤销了上一次的git commit
#返回到上次运行commit操作之前的状态,上次被commit的修改重新回到了index里面,但是注意:这并不是把当前HEAD所对应的内容复制到了index
#于是,我们回滚到了git commit的命令执行之前,但是注意,虽然回到了git commit命令执行之前,但是之前git commit所提交的那些修改内容并没有丢失,而是在index里面

#note:
#undo commits permanently:
#$ git commit ...
#$ git reset --hard HEAD~3
#the last three commits (HEAD, HEAD^, and HEAD~2) were bad and you do not want to ever see them again
#do not do this if you have already given these commits to somebody else
