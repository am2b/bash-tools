#!/usr/bin/env bash

#=tools
#@计算参数所指定的dir下的所有文件的sha256值
#@会在dir下生成一个dir同名的文本文件,该文本文件中的每一行就代表一个文件的sha256值
#@会递归遍历子目录
#@会忽略.DS_Store
#@usage:
#@script.sh dir

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir" >&2
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
}

check_envs() {
    if (("$#" == 0)); then
        return 0
    fi

    for var in "$@"; do
        #如果变量未导出或值为空
        if [ -z "$(printenv "$var" 2> /dev/null)" ]; then
            echo "error:this script uses unexported environment variables:${var}"
            return 1
        fi
    done

    return 0
}

check_parameters() {
    if (("$#" != 1)); then
        usage
    fi
}

process_opts() {
    while getopts ":h" opt; do
        case "$opt" in
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

main() {
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    local dir
    dir="${1}"
    if [[ ! -d "${dir}" ]]; then
        echo "error:${dir} is not a directory"
        exit 1
    fi

    local sha256_file
    sha256_file=$(basename "${dir}")_sha256.txt
    sha256_file="${dir}"/"${sha256_file}"

    #如果已经存在了sha256_file,则先清空
    if [[ -f "${sha256_file}" ]]; then : > "${sha256_file}"; fi

    local counter=0

    while IFS= read -r file; do
        if [[ "${file}" == "${sha256_file}" ]]; then continue; fi

        local value
        value=$(sha256sum "${file}" | awk '{print $1}')
        local file_base_name
        file_base_name=$(basename "${file}")
        #sha256的值用{[()]}括起来
        echo "${file_base_name}{[(${value})]}" >> "${sha256_file}"
        ((counter++))
    done < <(find_files_in_a_dir.sh -d "${dir}" -r -i .DS_Store)

    echo "共计${counter}个文件"
}

main "${@}"
