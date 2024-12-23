#!/usr/bin/env bash

#=git-branch
#@usage:
#@script.sh branch_name
#@无需提前git checkout branch_name

script=$(basename "$0")
arrow="--->"
usage="rebase branch_name to master"

usage() {
    echo "Usage:"
    echo "$script branch_name $arrow $usage"
    exit 1
}

while getopts "h" opt; do
    case $opt in
    h)
        usage
        ;;
    *)
        # 处理不支持的选项
        echo "error:unsupported option -$opt"
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if (($# != 1)); then
    usage
fi

# 检查当前是否在Git仓库中
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "错误:当前目录不是一个Git仓库"
    exit 1
fi

# 获取当前分支名称并保存
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 初始化变量用于跟踪stash状态
STASH_CREATED=false

# 检测当前分支是否有未提交的更改(包括工作区和暂存区)
# 没有差异返回0,有差异返回1
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "检测到未提交的更改,正在执行 stash 操作"
    STASH_MESSAGE="自动暂存:${CURRENT_BRANCH} 的未提交更改"
    #git stash -m "${STASH_MESSAGE}" 默认情况下,只会将工作区和暂存区的内容暂存
    git stash --include-untracked -m "${STASH_MESSAGE}"
    STASH_CREATED=true
    echo
fi

MASTER_BRANCH="master"
SOME_BRANCH="${1}"

# 检查是否存在master和SOME_BRANCH分支
if ! git show-ref --verify --quiet refs/heads/"${MASTER_BRANCH}"; then
    echo "错误:分支 ${MASTER_BRANCH} 不存在"
    exit 1
fi

if ! git show-ref --verify --quiet refs/heads/"${SOME_BRANCH}"; then
    echo "错误:分支 ${SOME_BRANCH} 不存在"
    exit 1
fi

# 获取master分支的最新提交(HEAD)
MASTER_HEAD=$(git rev-parse "${MASTER_BRANCH}")
# 获取master和SOME_BRANCH的共同祖先提交
SOME_BRANCH_BASE=$(git merge-base "${MASTER_BRANCH}" "${SOME_BRANCH}")

# 如果SOME_BRANCH的起始提交与master的HEAD相同,则直接快速合并
# 注意:这种情况下,即便SOME_BRANCH修改了master的同一个文件的同一行也不会产生合并冲突
if [[ $MASTER_HEAD == $SOME_BRANCH_BASE ]]; then
    echo "检测到 ${SOME_BRANCH} 的起始提交与 master 的 HEAD 相同,执行快速合并:"
    git checkout "${MASTER_BRANCH}" && git merge "${SOME_BRANCH}"
    if [ $? -eq 0 ]; then
        echo "${SOME_BRANCH} 分支已成功合并到 master 分支"

        if [ "$(git rev-parse --abbrev-ref HEAD)" != "$CURRENT_BRANCH" ]; then
            git checkout "${CURRENT_BRANCH}"
        fi
        # 恢复工作区并删除stash(如果有)
        if $STASH_CREATED; then
            git stash pop --index
        fi

        exit 0
    else
        echo "错误:合并操作失败"
        exit 1
    fi
fi

# 如果master分支有了新的独立提交
echo "检测到 master 分支有了新的提交"
echo "检查是否存在合并冲突:"
if git merge-tree "$(git merge-base HEAD ${SOME_BRANCH})" HEAD "${SOME_BRANCH}" >/dev/null; then
    echo "没有冲突,执行 rebase 操作"
    if [[ "$CURRENT_BRANCH" != "$SOME_BRANCH" ]]; then
        git checkout "${SOME_BRANCH}"
    fi
    git rebase "${MASTER_BRANCH}" && git checkout "${MASTER_BRANCH}" && git merge "${SOME_BRANCH}"
    if [ $? -eq 0 ]; then
        echo "rebase 操作成功完成"

        if [ "$(git rev-parse --abbrev-ref HEAD)" != "$CURRENT_BRANCH" ]; then
            git checkout "${CURRENT_BRANCH}"
        fi
        # 恢复工作区并删除stash(如果有)
        if $STASH_CREATED; then
            git stash pop --index
        fi

        exit 0
    else
        echo "错误:rebase 操作失败,请检查原因"
        exit 1
    fi
else
    echo "检测到合并冲突,已放弃rebase操作"
    echo "以下是存在冲突的文件:"
    git diff --name-only --diff-filter=U | bat --style=grid
    echo "==========注意=========="
    echo "先不要解决冲突"
    echo "请手动重新进行rebase或merge命令"
    echo "当再次指出存在冲突的时候再手动解决冲突"
    echo "然后:"
    echo "git add file,git rebase/merge --continue"
    exit 1
fi
