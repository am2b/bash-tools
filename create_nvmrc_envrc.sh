#!/usr/bin/env bash

#=node
#@create .nvmrc and .envrc in the current dir
#@usage:
#@script.sh 23.11.1

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script 23.11.1" >&2
    exit "${1:-1}"
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage 0
            ;;
        *)
            echo "error:unsupported option -$opt" >&2
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" != 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    cat <<EOF > .nvmrc
${1}
EOF

    cat <<'EOF' > .envrc
export NVM_DIR="$HOME/.config/nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"

if [[ -f .nvmrc ]]; then
    nvm use
else
    nvm use default
fi
EOF
}

main "${@}"
