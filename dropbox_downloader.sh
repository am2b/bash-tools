#!/usr/bin/env bash

#=tools
#@download dir or file from dropbox
#@usage:
#@script.sh remote_path_to_dir_or_file

function help()
{
cat << EOF
Usage:
download dir or file to the current dir
$(basename "$0") remote_path

Examples:
download a dir:
$(basename "$0") /arch/dir

download a file:
$(basename "$0") /arch/dir/file
EOF

exit 0
}

while getopts ':h' opt; do
    if [[ "$opt" == 'h' ]]; then
        help
    fi
done

shift $(("$OPTIND" - 1))

if (( "$#" == 0 )); then help; fi

remote_path="$1"
remote_dirname=$(dirname "$remote_path")
#这里的remote_basename有可能是一个文件夹的名字,也有可能是一个文件的名字
remote_basename=$(basename "$remote_path")
#如果是从remote下载一个文件夹的话,在命令行中传进来的参数如果最后是/的话,要删除掉/
remote_path="${remote_dirname}"/"${remote_basename}"

curl_download_https.sh "${DROPBOX_IMPL_URL}" /tmp/dp.sh

if [[ ! -f /tmp/dp.sh ]]; then
    exit 1
fi
#这里给定的/tmp/dropbox只是一个代表,其最后有可能表示一个文件夹也有可能表示一个文件
/tmp/dp.sh download "$remote_path" /tmp/dropbox

local_absolute_path=$(cd "$2" || exit; pwd)
#echo "$local_absolute_path"
#echo "${local_absolute_path}"/"${remote_basename}"
#这里mv的有可能是一个文件夹,也有可能是一个文件
mv /tmp/dropbox "${local_absolute_path}"/"${remote_basename}"
