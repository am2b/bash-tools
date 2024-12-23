#!/usr/bin/env bash

#=git-stash
#@应用stash，但是不删除栈上的条目

script=$(basename "$0")
arrow="--->"
usage="apply the top stash item and do not delete from stack"
usage_stash_index="apply the given index of a stash item and do not delete from stack"

# usage function
usage() {
    echo "Usage:"
    echo "$script $arrow $usage"
    echo "$script stash_index $arrow $usage_stash_index"
    exit 1
}

# check for help flag or invalid number of arguments
if [[ "$1" == "-h" || $# -gt 1 ]]; then
    usage
fi

# construct the git stash apply command
cmd=("git" "stash" "apply" "--index")

if [[ $# -eq 1 ]]; then
    stash_index="$1"
    stash_name="stash@{$stash_index}"
    cmd+=("$stash_name")
fi

# execute the command
"${cmd[@]}"
