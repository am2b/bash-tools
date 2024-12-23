#!/usr/bin/env bash

#=tools
#@create layout of swift command line

if [[ "$#" == 0 ]]; then
    echo "usage:script.sh project_name"
    exit 1
fi

mkdir -p "${1}"
cd "${1}" || exit 1
swift package init --type executable
current_path=$(pwd)
project_name=$(basename "${current_path}")
mkdir -p Sources/"${project_name}"
mv Sources/main.swift Sources/"${project_name}"/
