#!/usr/bin/env bash

#=tools
#@like command+c(or ctrl+c) for files and dirs

#如果没有参数的话,就退出
if (( $# == 0 )); then exit 0; fi

record_file=/tmp/simulate_command_c.txt

if [ -e "${record_file}" ]; then
    rm "${record_file}"
fi

for item in "${@}"; do
    realpath "${item}" >> "${record_file}"
done
