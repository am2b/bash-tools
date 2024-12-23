#!/usr/bin/env bash

#=tools
#@下载dropbox的共享链接

script_name=$(basename "$0")

function help()
{
cat << EOF
Usage:
"$script_name" [options] url

Examples:
print help:
"$script_name" -h

download a dropbox shared file or folder(as a zip package):
"$script_name" url
EOF
}

function main()
{
    while getopts ":h" opt; do
        case "$opt" in
            h | *) help && exit 1;;
        esac
    done

    shift $(("$OPTIND" - 1))

    if (( "$#" == 0 )); then
        help && exit 1
    fi

    #or:wget --content-disposition url
    curl -L -OJ "$1"
}

main "$@"

#specify name:
#curl -L -o wallpaper.jpg
#wget -O wallpaper.jpg
#curl -L -o dir.zip
#wget -O dir.zip
