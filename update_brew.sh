#!/usr/bin/env bash

#=tools
#@更新通过homebrew安装的包,但是除了perl

#update all package definitions and homebrew itself:
brew update

echo

#在/tmp生成一个临时文件,用于存放outdated的包名字,每行一个包名字
outdated_file=$(mktemp -t outdated.XXXXXX)
#填充该文件
brew outdated > "${outdated_file}"

#读取该文件
mapfile -t outdated_array < "${outdated_file}"
for package_name in "${outdated_array[@]}"; do
    #不更新perl
    if [[ "${package_name}" == 'perl' ]]; then
        continue
    fi

    brew upgrade "${package_name}"
done
