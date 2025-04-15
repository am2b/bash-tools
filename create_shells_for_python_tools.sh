#!/usr/bin/env bash

#=python
#@为python命令行程序批量创建可执行的外壳bash脚本
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

    local repos=~/repos
    local project_name
    local pyproject_file="pyproject.toml"

    for dir in "${repos}"/*; do
        local abs_pyproject_file="${dir}"/"${pyproject_file}"
        if [[ -f "${abs_pyproject_file}" ]]; then
            local how_to_run
            how_to_run=$(grep -w "how_to_run" "${abs_pyproject_file}" | awk -F' = ' '{print $2}')
            if [[ "${how_to_run}" == '"bash script"' ]]; then
                project_name=$(basename "${dir}")
                create_shell_for_python_tool.sh "${project_name}"
            fi
        fi
    done
}

main "${@}"
