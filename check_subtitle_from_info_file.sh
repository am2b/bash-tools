#!/usr/bin/env bash

#=ffmpeg
#@检查info文件中是否包含参数所指定语言的subtitle流,并且该语言的subtitle流是否只有一个
#@该脚本主要是被其它脚本调用
#@usage:
#@script.sh info_file [language]
#@info_file:脚本gen_video_subtitle_info.sh所生成的文件
#@language:默认为eng

usage() {
    local script
    script=$(basename "$0")
    echo "usage:" >&2
    echo "$script info_file [language]" >&2
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

main() {
    REQUIRED_TOOLS=()
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=("VIDEO_INFOS_DIR")
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    check_parameters "${@}"
    OPTIND=1
    process_opts "${@}"
    shift $((OPTIND - 1))

    local info_file="${1}"
    local lang=${2:-eng}

    #检查是否存在该语言的字幕,并统计数量
    read -r has_sub sub_count < <(
        awk -v lang="$lang" '
        BEGIN {count=0; is_sub=0; has_lang=0}
        {
            if ($0 ~ /^\[STREAM\]/) {
                if (is_sub && has_lang) count++
                is_sub=0; has_lang=0
            }
            if ($0 ~ /codec_type=subtitle/) is_sub=1
            if ($0 ~ ("TAG:language=" lang)) has_lang=1
        }
        END {
            if (is_sub && has_lang) count++
            has_sub = (count > 0 ? 1 : 0)
            print has_sub, count
        }
        ' "$info_file"
    )

    #输出结果
    local info_file_basename="${info_file##*/}"
    info_file_basename="${info_file_basename%_subtitle}"
    local not_found_file="${VIDEO_INFOS_DIR}"/check_not_found_subtitle
    local duplicate_file="${VIDEO_INFOS_DIR}"/check_duplicate_subtitle

    {
        echo "${info_file_basename}:"

        if [[ $has_sub -eq 1 ]]; then
            echo "✅ 发现 ${lang} 字幕流 (数量: ${sub_count})"
            #检查是否唯一
            if ((sub_count > 1)); then
                echo "⚠️ 警告: 发现多个 ${lang} 字幕流 (${sub_count} 个)"
                echo "${info_file_basename}:字幕流 (${lang}) 数量=${sub_count}" >> "${duplicate_file}"
            fi
        else
            echo "❌ 未发现 ${lang} 字幕流"
            echo "${info_file_basename}:字幕流 (${lang}) 未发现" >> "${not_found_file}"
        fi

        echo
    } | tee -a "${VIDEO_INFOS_DIR}/check_output_subtitle"
}

main "${@}"
