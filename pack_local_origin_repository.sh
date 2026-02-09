#!/usr/bin/env bash

#=pack
#@backup local origin repository
#@该脚本是被本地的"远程"仓库的hooks/post-receive来调用的
#@该脚本会打包仓库至iCloud,然后hooks/post-receive会处理留存于iCloud上面的压缩包的数量
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
    tar --exclude='.DS_Store' -cf "/tmp/${name_tar}" -C "${HOME}" ".${GITHUB_USERNAME}"
}

do_7z() {
    if ! password=$(security find-generic-password -s "local-origin-repository" -a "${GITHUB_USERNAME}" -w); then
        echo "error: did not get password from keychain"
        exit 1
    fi

    7z a -p"${password}" -mhe=on -mx=0 "/tmp/${name_7z}" "/tmp/${name_tar}" &>/dev/null
    rm "/tmp/${name_tar}"
}

do_move() {
    if [[ ! -d "${dest_dir}" ]]; then mkdir -p "${dest_dir}"; fi

    mv "/tmp/${name_7z}" "${dest_dir}"
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local TIMESTAMP

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    name_tar="origin_repo_${TIMESTAMP}.tar"
    name_7z="origin_repo_${TIMESTAMP}.7z"

    #一天只备份一次
    #if find "${dest_dir}" -type f -name "*$(date +"%Y-%m-%d")*" -print -quit | grep -q .; then
    #    exit 0
    #fi

    do_tar
    do_7z
    do_move
}

main "${@}"
