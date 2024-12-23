#!/usr/bin/env bash

#=tools
#@upload file to transfer.sh and download file from transfer.sh

#shellcheck disable=SC1090
source "$BASH_FUNCTIONS"

function help()
{
cat << EOF
-h print this help
-u upload to transfer.sh and save urls in /tmp/transfer.log
-d download from transfer.sh

examples:
upload:
$(basename "$0") -u /localpath/to/file

download(note:the file name should be same as the remote file):
$(basename "$0") -d XXXXXX /localpath/to/file
EOF
}

UPLOAD=0
DOWNLOAD=0
opts=:udh

while getopts "$opts" opt; do
    case "$opt" in
        u)
            UPLOAD=1
            ;;
        d)
            DOWNLOAD=1
            ;;
        h)
            help; exit 0
            ;;
        *)
            help; exit 1
            ;;
    esac
done

#shift options
shift $(("$OPTIND" - 1))

LOG=/tmp/transfer.log

if (( "$UPLOAD" )); then
    FILE_PATH="$1"; shift
    #to see the url that for deleting,just add -v option to curl
    curl --upload-file "$FILE_PATH" https://transfer.sh/"$(basename "$FILE_PATH")" -H "Max-Days: 3" | tee -a "$LOG"
    echo >> "$LOG"
elif (( "$DOWNLOAD" )); then
    CODE="$1"
    FILE_PATH="$2"
    mkdir -p "$(dirname "$FILE_PATH")"
    curl https://transfer.sh/"$CODE"/"$(basename "$FILE_PATH")" -o "$FILE_PATH"
fi
