#!/usr/bin/env bash

#=tools
#@create a file[.sh].bak from file[.sh],or a file[.sh] from file[.sh].bak

#@usage:
#@bak.sh file.sh -> file.sh.bak
#@bak.sh file.sh.bak -> file.sh

if (("${#}" != 1)); then
    exit 1
fi

if ! [ -f "${1}" ]; then
    exit 1
fi

filename=$(basename "${1}")
suffix="${filename##*.}"

if [[ "${suffix}" != 'bak' ]]; then
    new_filename="${filename}".bak
else
    #filename without bak
    new_filename="${filename%.*}"
fi

dir=$(dirname "${1}")
cd "${dir}" || exit 1

cp "${filename}" "${new_filename}"
