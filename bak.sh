#!/usr/bin/env bash

#=tools
#@create a file.bak from file,or create a file from file.bak
#@usage:
#@bak.sh file -> file.bak
#@bak.sh file.bak -> file

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script file"
    echo "$script file.bak"
    exit 1
}

check_parameters() {
    if (("$#" != 1)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    if ! [ -f "${1}" ]; then
        usage
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
}

main "${@}"
