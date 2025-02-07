#!/usr/bin/env bash

#=pack
#@backup local origin repository
#@usage:
#@script.sh

name_tar=""
name_7z=""
dest_dir="${ICLOUD_PATH}"/Origin

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 0
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
    if (("$#" > 1)); then
        usage
    fi
}

do_tar() {
    tar --exclude='.DS_Store' -cf "$name_tar" -C "${HOME}" ".${GITHUB_USERNAME}"
}

do_7z() {
    if ! password=$(security find-generic-password -s "local-origin-repository" -a "${GITHUB_USERNAME}" -w); then
        echo "error: did not get password from keychain"
        exit 1
    fi

    7z a -p"${password}" -mhe=on -mx=0 "${name_7z}" "${name_tar}" &>/dev/null
    rm "${name_tar}"
}

do_move() {
    local from_dir
    local from_abs_dir
    local to_abs_dir

    from_dir=$(dirname "${name_7z}")
    from_abs_dir=$(realpath "${from_dir}")
    to_abs_dir=$(realpath "${dest_dir}")
    if [[ "${from_abs_dir}" != "${to_abs_dir}" ]]; then
        mv "${name_7z}" "${to_abs_dir}"
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local TIMESTAMP

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    name_tar="origin_repo_${TIMESTAMP}.tar"
    name_7z="origin_repo_${TIMESTAMP}.7z"

    if [[ ! -d "${dest_dir}" ]]; then mkdir -p "${dest_dir}"; fi

    #一天只备份一次
    #if find "${dest_dir}" -type f -name "*$(date +"%Y-%m-%d")*" -print -quit | grep -q .; then
    #    exit 0
    #fi

    do_tar
    do_7z
    do_move
}

main "${@}"
