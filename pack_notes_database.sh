#!/usr/bin/env bash

#=pack
#@backup notes database on mac
#@usage:
#@nohup script.sh > /tmp/notes.log 2>&1 &

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "nohup $script > /tmp/notes.log 2>&1 &"
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

copy_from="${HOME}/Library/Group Containers/group.com.apple.notes"
copy_to="${HOME}"/DownLoads/notes/
if [[ ! -d "${copy_to}" ]]; then
    mkdir -p "${copy_to}"
fi
cp -r "${copy_from}" "${copy_to}"

TIMESTAMP=$(date +"%Y%m%d")
archive_name="Notes-${TIMESTAMP}"
archive_name_tar="${archive_name}".tar
archive_name_7z="${archive_name}".7z

tar --exclude='.DS_Store' -cf "$archive_name_tar" -C "${HOME}/Downloads" notes

password=$(security find-generic-password -s "notes-database" -a "backup" -w)
if [[ $? -ne 0 ]]; then
    echo "error:did not get password from keychain"
    exit 1
fi

7z -xr!'.DS_Store' a -p"${password}" -mhe=on -mx=0 "${archive_name_7z}" "${archive_name_tar}" &>/dev/null

if [[ ! -f "${HOME}"/Downloads/"${archive_name_7z}" ]]; then
    mv "${archive_name_7z}" "${HOME}"/DownLoads
fi

rm "${archive_name_tar}"
rm -rf "${copy_to}"
osascript -e 'display notification "打包备忘录的任务已完成" with title "打包备忘录" sound name "Glass"'
