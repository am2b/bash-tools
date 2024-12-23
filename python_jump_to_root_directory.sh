#!/usr/bin/env bash

#=python
#@从python项目的任意子目录跳转到根目录
#@usage:source script.sh

# 定义标识项目根目录的文件
ROOT_MARKERS=("pyproject.toml" ".git")

# 从当前目录开始递归向上查找
find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        for marker in "${ROOT_MARKERS[@]}"; do
            if [ -e "$dir/$marker" ]; then
                echo "$dir"
                return 0
            fi
        done
        dir=$(dirname "$dir")
    done
    return 1
}

# 获取项目根目录
project_root=$(find_project_root)

# 如果找到了项目根目录，则跳转
if [ -n "$project_root" ]; then
    cd "$project_root" || exit
fi
