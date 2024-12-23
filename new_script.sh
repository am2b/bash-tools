#!/usr/bin/env bash

#=tools
#@create a new script

params_size="$#"

if (( params_size == 0 )) || (( params_size > 2 )); then
    exit 1
fi

script_name="${1}"
if (( params_size == 2 )); then
    script_name="${1}"."${2}"
fi

if [ -f "${script_name}" ]; then
    echo "${script_name}" already exists
    exit 1
fi

touch "${script_name}"
chmod 755 "${script_name}"
nvim "${script_name}"
