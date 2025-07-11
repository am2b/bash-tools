#!/usr/bin/env bash

#=pack
#@backup music library on mac
#@usage:
#@nohup script.sh > /tmp/music.log 2>&1 &

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "nohup $script > /tmp/music.log 2>&1 &"
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

if (("$#" > 1)); then
    usage
fi

if pgrep -x "Music" >/dev/null; then
    osascript -e 'tell application "Music" to quit'
    sleep 5
fi

src_dir="/Volumes/T7/Apps/music/"
src_parent_dir=$(dirname "${src_dir}")

TIMESTAMP=$(date +"%Y-%m-%d")
archive="Music-${TIMESTAMP}.7z"

password=$(security find-generic-password -s "Music-Library" -a "backup" -w) || {
    echo "error:did not get password from keychain"
    exit 1
}

cd "${src_parent_dir}" || exit 1
7z -xr!'.DS_Store' a -p"${password}" -mhe=on -mx=0 ~/Downloads/"${archive}" "${src_dir}" &>/dev/null

osascript -e 'display notification "打包音乐的任务已完成" with title "打包音乐" sound name "Glass"'
