#!/usr/bin/env bash

#=git-branch
#@备份master分支为master-backup,master-backup分支是跟踪分支

usage() {
    echo "Usage:"
    echo "$0 ---> backup master with upstream info"
}

if [[ "$1" == "-h" || "$#" -gt 0 ]]; then
    usage
    exit 0
fi

git branch -c master master-backup
