#!/usr/bin/env bash

#=git-branch
#@按类别打印分支的状态

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "the current directory is not a git repository"
    exit 1
fi

if (($# != 0)); then
    echo "usage:$(basename "$0")"
    exit 1
fi

category_a=()
category_b=()
category_c=()
category_d=()

# 获取所有分支列表(不包括 master)
branches=$(git branch --format="%(refname:short)" | grep -v '^master$')

for branch in $branches; do
    # 获取提交比较信息
    commits_in_branch_not_in_master=$(git log master.."$branch" --oneline)
    commits_in_master_not_in_branch=$(git log "$branch"..master --oneline)

    if [[ -z "$commits_in_branch_not_in_master" && -z "$commits_in_master_not_in_branch" ]]; then
        #类别A:分支和master完全同步
        category_a+=("$branch")
    elif [[ -n "$commits_in_branch_not_in_master" && -z "$commits_in_master_not_in_branch" ]]; then
        # 类别B:分支有提交未合并到master,但master完全包含分支
        category_b+=("$branch")
    elif [[ -z "$commits_in_branch_not_in_master" && -n "$commits_in_master_not_in_branch" ]]; then
        # 类别C:分支的提交已完全合并到master,但master有额外提交
        category_c+=("$branch")
    elif [[ -n "$commits_in_branch_not_in_master" && -n "$commits_in_master_not_in_branch" ]]; then
        # 类别D:分支和master各有未合并的提交
        category_d+=("$branch")
    fi
done

desc_a="master === "
desc_b="master <=== "
desc_c="master ===> "
desc_d="master <===> "

print() {
    local desc="${1}"
    shift
    local arr=("$@")
    size="${#arr[@]}"
    if ((size > 0)); then
        echo -n "${desc}"
        IFS=","
        echo "${arr[*]}"
        unset IFS
    fi
}

print "${desc_a}" "${category_a[@]}"
print "${desc_b}" "${category_b[@]}"
print "${desc_c}" "${category_c[@]}"
print "${desc_d}" "${category_d[@]}"
