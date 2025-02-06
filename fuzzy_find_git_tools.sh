#!/usr/bin/env bash

#=tools
#@fuzzy find a git script
#@usage:
#@source fuzzy_find_git_tools.sh

dir="${HOME}"/repos/bash-tools
selected_script=$(find "${dir}" -path "${dir}"/.git -prune -o -name "*git*" -type f -print | sed "s|^$HOME/repos/bash-tools/||" | fzf --preview "bat -n --color=always {}")

if [[ -n "$selected_script" ]]; then
    selected_script=$(basename "${selected_script}")
    print -z "${selected_script}"
fi
