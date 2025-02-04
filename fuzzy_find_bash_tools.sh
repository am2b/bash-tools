#!/usr/bin/env bash

#=tools
#@fuzzy find a bash script
#@usage:
#@source fuzzy_find_bash_tools.sh

dir="${HOME}"/repos/bash-tools
selected_script=$(find "${dir}" -path "${dir}"/.git -prune -o -type f -print | sed "s|^$HOME/repos/bash-tools/||" | fzf)

if [[ -n "$selected_script" ]]; then
    selected_script=$(basename "${selected_script}")
    print -z "${selected_script}"
fi
