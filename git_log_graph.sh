#!/usr/bin/env bash

#=git-log
#@看分支结构

git log --graph --decorate --all --color=always | bat
