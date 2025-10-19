#!/usr/bin/env bash

#=ffmpeg
#@检查info文件中是否包含参数所指定语言的audio和subtitle流
#@该脚本主要是被其它脚本调用
#@usage:
#@script.sh info_file [language]
#@info_file:脚本gen_video_info.sh所生成的文件
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
        if ! command -v "${tool}" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
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
    #用a来表示"是否发现目标语言的音频流":
    #0:没发现
    #1:发现了

    #检查是否存在该语言的音频
    local has_audio
    has_audio=$(awk -v lang="$lang" '
    BEGIN {a=0; is_audio=0; has_lang=0}
    {
        if ($0 ~ /^\[STREAM\]/) {
            #新块开始前,先检查上一个块
            if (is_audio && has_lang) a=1
            #重置状态
            is_audio=0; has_lang=0
        }
        if ($0 ~ /codec_type=audio/) is_audio=1
        if ($0 ~ ("TAG:language=" lang)) has_lang=1
    }
    END {
        #检查最后一个块
        if (is_audio && has_lang) a=1
        print a
    }
    ' "$info_file")

    #检查是否存在该语言的字幕
    local has_sub
    has_sub=$(awk -v lang="$lang" '
    BEGIN {a=0; is_sub=0; has_lang=0}
    {
        if ($0 ~ /^\[STREAM\]/) {
            if (is_sub && has_lang) a=1
            is_sub=0; has_lang=0
        }
        if ($0 ~ /codec_type=subtitle/) is_sub=1
        if ($0 ~ ("TAG:language=" lang)) has_lang=1
    }
    END {
        if (is_sub && has_lang) a=1
        print a
    }
    ' "$info_file")

    #输出结果
    local info_file_basename="${info_file##*/}"
    local not_found_file=/tmp/video_infos/not_found
    {
        echo "${info_file_basename}:"
        [[ $has_audio -eq 1 ]] && echo "✅ 发现 ${lang} 音频流" || { echo "❌ 未发现 ${lang} 音频流"; echo "${info_file_basename}:音频流" >> "${not_found_file}"; }
        [[ $has_sub   -eq 1 ]] && echo "✅ 发现 ${lang} 字幕流" || { echo "❌ 未发现 ${lang} 字幕流"; echo "${info_file_basename}:字幕流" >> "${not_found_file}"; }
        echo
    } | tee -a /tmp/video_infos/infos
}

main "${@}"
