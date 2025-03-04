#!/usr/bin/env bash

#=pack
#@backup photo library on mac
#@usage:
#@nohup script.sh > /tmp/photo.log 2>&1 &

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "nohup $script > /tmp/photo.log 2>&1 &"
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

copy_from="/Volumes/T7/Apps/photos"
copy_to="${HOME}"/DownLoads
dest_dir_name="photos"

absolute_photos="${copy_to}"/"${dest_dir_name}"
if [[ -d "${absolute_photos}" ]]; then
    echo "error:there is a directory:${absolute_photos}"
    exit 1
fi

cp -r "${copy_from}" "${copy_to}"

TIMESTAMP=$(date +"%Y%m%d")
archive_name="Photos-${TIMESTAMP}"
archive_name_tar="${archive_name}".tar
archive_name_7z="${archive_name}".7z

tar --exclude='.DS_Store' -cf "$archive_name_tar" -C "${copy_to}" "${dest_dir_name}"

password=$(security find-generic-password -s "Photos-Library" -a "backup" -w)
if [[ $? -ne 0 ]]; then
    echo "error:did not get password from keychain"
    exit 1
fi

7z -xr!'.DS_Store' a -p"${password}" -mhe=on -mx=0 "${archive_name_7z}" "${archive_name_tar}" &>/dev/null

if [[ ! -f "${HOME}"/Downloads/"${archive_name_7z}" ]]; then
    mv "${archive_name_7z}" "${HOME}"/DownLoads
fi

rm "${archive_name_tar}"
