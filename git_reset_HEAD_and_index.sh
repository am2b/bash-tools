#!/usr/bin/env bash

#=git-reset
#@重置本地的HEAD到某个提交,然后用该提交来填充index(回退到git add之前,工作区被修改之后)

script=$(basename "$0")
usage() {
    echo "Usage:"
    echo "$script ---> reset HEAD to HEAD~"
    echo "$script <commit> ---> reset HEAD to <commit> and update the index with the contents of whatever snapshot HEAD now points to"
}

if [[ "$1" == "-h" || "$#" -gt 1 ]]; then
    usage
    exit 0
fi

cmd="git reset --mixed"
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

#--mixed:
#reset会用HEAD(after reset)指向的快照内容来更新index
#git reset [--mixed] HEAD~:
#它会撤销上次提交,还会把reset之后HEAD所指向的内容复制到index,也就是说reset后,通过git restore --cached会显示没有差别
#但是,别忘了,上次git commit所提交的那些修改,依然还在working tree里面
#于是,我们回滚到了git add和git commit的命令执行之前

#索引:
#索引是你的预期的下一次提交。我们也会将这个概念引用为Git的"暂存区域",这就是当你运行 "git commit"时Git看起来的样子
#Git将上一次检出到工作目录中的所有文件填充到索引区,它们看起来就像最初被检出时的样子。之后你会将其中一些文件替换为新版本,接着通过"git commit"将它们转换为树来用作新的提交
#git ls-files -s
#它会显示出索引当前的样子
