#!/usr/bin/env bash

#=git-libs
#@各种get

get_current_branch_name() {
    local current_branch_name
    current_branch_name=$(git rev-parse --abbrev-ref HEAD)
    echo "${current_branch_name}"
}

get_branch_HEAD() {
    local branch="${1}"
    local HEAD
    HEAD=$(git rev-parse "${branch}")
    echo "${HEAD}"
}

get_common_ancestor_commit() {
    local branch_a="${1}"
    local branch_b="${2}"
    local common_ancestor
    common_ancestor=$(git merge-base "${branch_a}" "${branch_b}")
    echo "${common_ancestor}"
}
