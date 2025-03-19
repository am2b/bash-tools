#!/usr/bin/env bash

#=tools
#@create a file/dir.bak from file/dir,or create a file/dir from file/dir.bak
#@usage:
#@bak.sh file/dir -> file/dir.bak
#@bak.sh file/dir.bak -> file/dir

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script file/dir"
    echo "$script file/dir.bak"
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

bak_file() {
    cd "${dir_name}" || exit 1

    cp "${base_name}" "${new_name}"
}

bak_dir() {
    cd "${dir_name}" || exit 1

    if [[ -d "${new_name}" ]]; then
        local TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
        local unique_name="${new_name}_${TIMESTAMP}"
        mv "${new_name}" "${unique_name}"
        trash "${unique_name}"
    fi

    cp -R "${base_name}" "${new_name}"
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local tools=("trash")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "error:$tool is not installed"
            exit 1
        fi
    done

    if [[ ! -d "${HOME}"/.trash ]]; then
        echo "error:no trash can found"
        exit 1
    fi

    if [[ ! -f "${1}" && ! -d "${1}" ]]; then
        usage
    fi

    base_name=$(basename "${1}")
    suffix="${base_name##*.}"

    if [[ "${suffix}" != 'bak' ]]; then
        #add suffix:.bak
        new_name="${base_name}".bak
    else
        #remove suffix:.bak
        new_name="${base_name%.*}"
    fi

    dir_name=$(dirname "${1}")

    if [[ -f "${1}" ]]; then
        bak_file "${1}"
        exit 0
    fi

    if [[ -d "${1}" ]]; then
        bak_dir "${1}"
        exit 0
    fi
}

main "${@}"
