#!/usr/bin/env bash

#=text
#@parse key value pairs
#@usage:
#@script.sh key_value_file[.txt]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script key_value_file[.txt]"
    exit 0
}

while getopts "h" opt; do
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
shift $((OPTIND - 1))

if (("$#" != 1)); then
    usage
fi

config_file="${1}"

if [[ ! -f "$config_file" ]]; then
    echo "${config_file} do not exist"
    exit 1
fi

declare -A config

#读取配置文件并解析
while IFS='=' read -r key value; do
    #跳过注释行和空行
    if [[ "$key" =~ ^#.*$ ]] || [[ -z "$key" ]]; then
        continue
    fi

    #去掉可能的(左右)空格
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    config["$key"]="$value"
done < "$config_file"

#可选
echo "配置文件内容解析完成:"
for key in "${!config[@]}"; do
    echo "$key = ${config[$key]}"
done
