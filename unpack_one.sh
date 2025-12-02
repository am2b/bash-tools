#!/usr/bin/env bash

#=pack
#@解压一个包,或者目录下的所有包,这些包的密码都在保险箱one里面
#@默认解压到包所在的目录,可以通过选项-o指定输出目录
#@usage:
#@script.sh file/dir
#@script.sh -o output_dir file/dir

output_dir=""
password=""

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script file/dir" >&2
    echo "$script -o output_dir file/dir" >&2
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
    while getopts ":ho:" opt; do
        case "$opt" in
            h)
                usage 0
                ;;
            o)
                output_dir="${OPTARG}"
                ;;
            *)
                echo "error:unsupported option -$opt" >&2
                usage
                ;;
        esac
    done
}

get_password() {
    local name
    name=$(basename "${1}")
    # 移除后缀名.7z
    name=${name%.7z}
    # 如果有空格的话,替换为-
    name="${name// /-}"
    local password_file="${SAFE_ONE}/${name}"

    if [[ ! -r "${password_file}" ]]; then
        echo "密码文件:${password_file}不存在或无法读取"
        exit 1
    fi

    password=$(awk '/^密码$/ {getline; print}' "${password_file}")
    if [[ -z "${password}" ]]; then
        echo "读取密码失败"
        exit 1
    fi
}

unpack_7z() {
    local pack="${1}"

    7z x "${pack}" -p"${password}" -o"${output_dir}" 1> /dev/null
}

set_output_dir() {
    local input="${1}"

    # 包所在的目录
    local dir_name
    dir_name=$(dirname "${input}")
    dir_name=$(realpath "${dir_name}")

    # 如果没有通过选项指定输出目录的话,就将输出目录设置为包所在的目录
    if [[ -z "${output_dir}" ]]; then
        output_dir="${dir_name}"
    fi
}

main() {
    REQUIRED_TOOLS=(7z)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=(SAFE_ONE)
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    local input="${1}"

    if [[ -f "${input}" ]]; then
        get_password "${input}"
        set_output_dir "${input}"
        unpack_7z "${input}"
    fi

    if [[ -d "${input}" ]]; then
        while IFS= read -r file; do
            get_password "${file}"
            set_output_dir "${file}"
            unpack_7z "${file}"
        done < <(find_files_in_a_dir.sh -d "${input}" -e ".7z")
    fi
}

main "${@}"
