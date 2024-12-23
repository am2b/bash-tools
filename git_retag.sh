#!/usr/bin/env bash

#=git-tag
#@重新打标签
#@usage: script.sh tag_name

if [ -z "$1" ]; then
    echo "Error: Tag name is required."
    echo "Usage: $0 tag_name"
    exit 1
fi

tag_name="${1}"

# 删除本地标签
if ! git tag -d "${tag_name}"; then
    echo "Error: Failed to delete local tag '${tag_name}'"
    exit 1
fi

# 删除远程标签
if ! git push origin :refs/tags/"${tag_name}"; then
    echo "Error: Failed to delete remote tag '${tag_name}'"
    exit 1
fi

# 重新打标签
if ! git tag "${tag_name}"; then
    echo "Error: Failed to create tag '${tag_name}'"
    exit 1
fi

# 重新推送标签
if ! git push origin "${tag_name}"; then
    echo "Error: Failed to push tag '${tag_name}' to remote"
    exit 1
fi

echo "Tag '${tag_name}' successfully recreated and pushed."
