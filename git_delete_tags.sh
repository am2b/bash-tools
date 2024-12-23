#!/usr/bin/env bash

#=git-tag
#@删除本地标签,同时删除远程仓库中的标签

script=$(basename "$0")
arrow="--->"
usage="delete tag on local and remote repository"

# Usage function
usage() {
    echo "Usage:"
    echo "$script tag $arrow $usage"
    exit 1
}

# 检查是否提供了标签名
if [[ $# -ne 1 ]]; then
    usage
fi

tag="$1"

# 删除本地标签
git tag -d "$tag" || {
    echo "Failed to delete local tag: $tag"
    exit 1
}

# 删除远程标签
git push origin --delete "$tag" || {
    echo "Failed to delete remote tag: $tag"
    exit 1
}

#删除掉本地仓库上的标签:
#git tag -d v1.0
#上述命令并不会从远程仓库中移除这个标签，你必须用git push <remote> :refs/tags/<tagname>来更新远程仓库：
#将冒号前面的空值推送到远程标签名，从而高效地删除它
#git push origin :refs/tags/v1.0
#更直观的删除远程仓库标签的方式是：
#git push origin --delete <tagname>
