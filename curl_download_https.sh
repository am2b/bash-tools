#!/usr/bin/env bash

#=transfer
#@download a file from https by curl
#@usage:
#@script.sh url [path/local_file]

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script url [path/local_file]"
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

local_file=""
param_count="$#"
if (("${param_count}" < 1)) || (("${param_count}" > 2)); then
    usage
fi
url="${1}"
if (("${param_count}" == 2)); then
    local_file="${2}"
    path=$(dirname "${local_file}")
    if [[ ! -d "${path}" ]]; then
        mkdir -p "${path}"
    fi
fi

#重试3次
retry=3
#重试间隔3秒
retry_delay=3

if [[ -n "${local_file}" ]]; then
    http_status=$(curl --silent --retry "${retry}" --retry-delay "${retry_delay}" -w '%{http_code}' -o "${local_file}" "${url}")
else
    http_status=$(curl --silent --retry "${retry}" --retry-delay "${retry_delay}" -w '%{http_code}' "${url}")
fi

#检查curl命令的退出状态
exit_status=$?

if [ $exit_status -eq 0 ]; then
    #下载成功时,根据HTTP状态码判断
    if [ "$http_status" -eq 200 ]; then
        echo "下载成功,文件已保存为:${local_file}"
    else
        echo "下载完成,但HTTP状态码为:$http_status,可能存在问题"
    fi
else
    #下载失败时,根据HTTP状态码打印不同消息
    case $http_status in
    404)
        echo "下载失败:文件未找到(HTTP 404)"
        ;;
    500)
        echo "下载失败:服务器内部错误(HTTP 500)"
        ;;
    403)
        echo "下载失败:权限不足或被禁止访问(HTTP 403)"
        ;;
    0)
        echo "下载失败:网络连接问题或无法解析主机名"
        ;;
    *)
        echo "下载失败:未知错误(HTTP $http_status)"
        ;;
    esac
fi
