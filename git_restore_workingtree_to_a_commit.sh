#!/usr/bin/env bash

#=git-tree
#@丢弃工作区的修改,然后用某个指定的提交来填充工作区,暂存区里面的状态没有被改变

#丢弃当前工作区修改,然后恢复当前工作区到某个指定的提交
#注意:
#1,暂存区里面的状态没有被改变
#2,只是恢复了工作区里面的内容,并没有改变HEAD所指向的提交

#恢复当前工作区到上上次提交(会同时恢复当前工作区里面子目录下的内容,但是不会影响当前工作区上层(父目录里面)的内容):
#restore_workingtree_to_a_commit.pl HEAD~ .

#也可以指定某个提交记录的哈希值:
#restore_workingtree_to_a_commit.pl 7173808e some_file[s]

script="restore_workingtree_to_a_commit.sh"
arrow="--->"
usage_string="discard working tree (current path), and then restore working tree (current path) to a given commit"
usage_string_files="discard file[s], and then restore the file[s] to a given commit"

# usage function
usage() {
    echo "Usage:"
    echo "$script ref . $arrow $usage_string"
    echo "$script ref file[s] $arrow $usage_string_files"
    exit 1
}

# check if "-h" is passed or less than 2 arguments are provided
if [[ "$1" == "-h" || $# -lt 2 ]]; then
    usage
fi

# construct the git restore command
cmd="git restore --source $1"
# remove the first argument (commit ref)
shift

# append remaining arguments (paths or "." for current directory)
for arg in "$@"; do
    cmd="$cmd $arg"
done

#可以直接通过管道传递yes以跳过交互式确认
#这里的yes是一个命令行命令
#yes | restore_workingtree_to_a_commit.sh HEAD~ .
#或者
#echo 'y' | restore_workingtree_to_a_commit.sh HEAD~ .

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
    # execute the constructed command
    eval "$cmd"
fi
