#!/usr/bin/env bash

#=git-libs
#@各种检查

check_in_git_repository() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    else
        echo "the current directory is not a git repository"
        return 1
    fi
}

check_workingtree_clean() {
    if git diff --quiet; then
        return 0
    else
        echo "the working tree is not clean"
        return 1
    fi
}

check_index_clean() {
    if git diff --cached --quiet; then
        return 0
    else
        echo "the index is not clean"
        return 1
    fi
}

check_branch_exists() {
    local branch="${1}"
    if git show-ref --verify --quiet refs/heads/"${branch}"; then
        return 0
    else
        echo "${branch} does not exist"
        return 1
    fi
}

#HEAD可以看作是master,因为合并操作是在master分支上进行的
check_no_merge_conflicts() {
    local branch="${1}"
    if git merge-tree "$(git merge-base HEAD ${branch})" HEAD "${branch}" >/dev/null; then
        return 0
    else
        echo "there are merge conflicts"
        return 1
    fi
}
