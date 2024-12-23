#!/usr/bin/env bash

#=convenient
#@open perl doc with nvim -R

if (( "$#" == 0 )) || (( "$#" > 2 )); then
    exit 1
fi

doc_name="${1}"

if (( "$#" == 2 )); then
    doc_name="${1}"::"${2}"
fi

perldoc "${doc_name}" | nvim -R
