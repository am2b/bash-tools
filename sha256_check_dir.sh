#!/usr/bin/env bash

#=tools
#@计算参数所指定的dir下的所有文件的sha256值
#@然后与参数所指定的sha256.txt进行比较,如果有文件没有完全匹配,则报错
#@如果没有指定sha256.txt,那么默认使用dir目录下的dir_sha256.txt文件
#@会递归遍历子目录
#@会忽略.DS_Store
#@usage:
#@script.sh dir [sha256.txt]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script dir [sha256.txt]" >&2
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
    if (("$#" < 1 || "$#" > 2)); then
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
    sha256_file="${2}"
    if [[ -z "${sha256_file}" ]]; then
        sha256_file=$(basename "${dir}")_sha256.txt
        sha256_file="${dir}"/"${sha256_file}"
    fi

    if [[ ! -f "${sha256_file}" ]]; then
        echo "error:${sha256_file} is not a file"
        exit 1
    fi

    #dir目录下文件的数量(不包含dir_sha256.txt文件)
    local files_num
    local sha256_file_basename
    sha256_file_basename=$(basename "${sha256_file}")
    files_num=$(count_files_in_a_dir.sh -d "${dir}" -r -i .DS_Store,"${sha256_file_basename}")

    #sha256_file的行数
    local lines
    lines=$(cat "${sha256_file}" | wc -l)

    if (("${files_num}" != "${lines}")); then
        echo "error:文件数量与sha256的行数不匹配"
        echo "文件数量:${files_num}"
        echo "sha256的行数:${lines}"
        exit 1
    fi

    #计算每个文件的sha256,然后与记录sha256的文件进行匹配
    while IFS= read -r file; do
        if [[ "${file}" == "${sha256_file}" ]]; then continue; fi

        local value
        value=$(sha256sum "${file}" | awk '{print $1}')

        local file_basename
        file_basename=$(basename "${file}")

        local expected_string="${file_basename}{[(${value})]}"

        #-F(--fixed-strings):纯文本匹配,而非正则表达式,把要搜索的字符串当作纯文本处理,忽略其中的正则特殊字符(如()[]{}*+`等)
        #-x(--line-regexp):匹配整行,而非行内部分内容
        #-q(--quiet/--silent):静默模式,不输出任何内容,执行后不打印匹配结果,仅通过退出状态码告知是否匹配成功
        if ! grep -Fxq "${expected_string}" "${sha256_file}"; then
            echo "发生匹配错误:${file_basename}"
        fi
    done < <(find_files_in_a_dir.sh -d "${dir}" -r -i .DS_Store)
}

main "${@}"
