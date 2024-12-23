#!/usr/bin/env bash

#=git-branch
#@设置当前分支去跟踪一个远程分支,或者修改当前分支正在跟踪的上游分支

usage() {
    echo "Usage:"
    echo "$(basename "$0") origin_branch ---> set or change the upstream tracked by the current local branch"
}

while getopts ":h" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

branch_name="$1"

#更新所有远程仓库的分支信息
git fetch --all

#将当前的本地分支设置为跟踪远程分支origin/$branch_name
git branch --set-upstream-to=origin/"$branch_name"

#运行成功后,使用以下命令验证设置:
#git branch -vv

#当设置好跟踪分支后,可以通过简写@{upstream}或@{u}来引用它的上游分支

#下面两句命令有什么不同?
#git branch --set-upstream-to=origin/"$branch_name"
#git branch --set-upstream-to origin/"$branch_name"
#答:完全相同,因为Git可以自动识别选项和参数的关系,无论是否使用=

#下面两句命令有什么不同?
#git branch --set-upstream-to=origin/"$branch_name"
#git branch --set-upstream-to=origin/"$branch_name" "$branch_name"
#答:
#第一个命令影响的是当前检出的本地分支
#第二个命令影响的是最后参数所表示的本地分支,这里的$branch_name既被用作远程分支名,又作为本地分支的目标(注意:执行第二个命令的时候无需先checkout出$branch_name分支)
#如果当前已经在$branch_name分支上,那么第一条命令和第二条命令的效果是相同的

#下面两句命令有什么不同?
#git branch --set-upstream-to origin/"$branch_name"
#git branch -u origin/"$branch_name"
#答:完全相同,-u是--set-upstream-to的简写

#是不是当设置好跟踪分支后,可以通过简写@{upstream}或@{u}来引用它的上游分支
#答:是
#举例:
#假设有一个本地分支feature,并且该分支已经设置了上游分支为origin/feature,你可以使用git fetch获取远程仓库的更新,然后使用@{upstream}或@{u}来合并远程分支的改动到本地分支
#执行git fetch获取远程更新:
#git fetch
#git fetch会从远程仓库拉取更新,但不会自动合并这些更改到当前分支,它会更新本地的远程跟踪分支(比如origin/feature),但不会更新本地的工作分支(比如feature)
#如果你想将上游分支(即远程分支origin/feature)的最新更改合并到本地的feature分支,你可以使用以下命令:
#git merge @{upstream}或git merge @{u},这二者相同
