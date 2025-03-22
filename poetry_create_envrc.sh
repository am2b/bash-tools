#!/usr/bin/env bash

#=python
#@create .envrc in the current directory(created by poetry) for direnv
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
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

check_parameters() {
    if (("$#" != 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #'EOF':do not interpret variables in the text,then use single quotes
    cat <<'EOF' >.envrc
export VIRTUAL_ENV=$(poetry env info --path)
layout python $VIRTUAL_ENV/bin/python
EOF
}

main "${@}"
