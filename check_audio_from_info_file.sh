#!/usr/bin/env bash

#=ffmpeg
#@检查info文件中是否包含参数所指定语言的audio流,并且该语言的audio流是否只有一个
#@该脚本主要是被其它脚本调用
#@usage:
#@script.sh info_file [language]
#@info_file:脚本gen_video_audio_info.sh所生成的文件
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

    #在awk语法中,缩进(空格或制表符)对语义没有影响
    #$0 ~ ("TAG:language=" lang)
    #~是正则匹配运算符,这行的意思是:
    #"TAG:language=" lang是字符串拼接,awk会自动把"TAG:language="与变量lang连接起来
    #如果当前行中包含TAG:language=语言变量的值,则匹配成功

    #检查是否存在该语言的音频,并统计数量
    read -r has_audio audio_count < <(
        awk -v lang="$lang" '
        BEGIN {count=0; is_audio=0; has_lang=0}
        {
            if ($0 ~ /^\[STREAM\]/) {
                if (is_audio && has_lang) count++
                is_audio=0; has_lang=0
            }
            if ($0 ~ /codec_type=audio/) is_audio=1
            if ($0 ~ ("TAG:language=" lang)) has_lang=1
        }
        END {
            if (is_audio && has_lang) count++
            has_audio = (count > 0 ? 1 : 0)
            print has_audio, count
        }
        ' "$info_file"
    )

    #输出结果
    local info_file_basename="${info_file##*/}"
    info_file_basename="${info_file_basename%_audio}"
    local not_found_file="${VIDEO_INFOS_DIR}"/check_not_found_audio
    local duplicate_file="${VIDEO_INFOS_DIR}"/check_duplicate_audio

    #打印是否发现的结果到终端,同时将检查结果存储一份到check_output_audio
    #如果存在未发现的情况，还要将其存储到check_not_found_audio文件
    #这里会往check_not_found_audio里面不断的追加信息,不过没关系,因为如果只是check一个视频文件的话,直接看终端的输出即可,如果是check一个目录的话,那么会在check该目录之前先删除整个VIDEO_INFOS_DIR目录里面的全部文件
    #check_output_audio,check_duplicate_audio同理
    {
        echo "${info_file_basename}:"

        if [[ $has_audio -eq 1 ]]; then
            echo "✅ 发现 ${lang} 音频流 (数量: ${audio_count})"
            #检查是否唯一
            if ((audio_count > 1)); then
                echo "⚠️ 警告: 发现多个 ${lang} 音频流 (${audio_count} 个)"
                echo "${info_file_basename}:音频流 (${lang}) 数量=${audio_count}" >> "${duplicate_file}"
            fi
        else
            echo "❌ 未发现 ${lang} 音频流"
            echo "${info_file_basename}:音频流 (${lang}) 未发现" >> "${not_found_file}"
        fi

        echo
    } | tee -a "${VIDEO_INFOS_DIR}/check_output_audio"
}

main "${@}"
