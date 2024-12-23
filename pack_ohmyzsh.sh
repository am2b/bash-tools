#!/usr/bin/env bash

#=pack
#@pack the dir of ~/.oh-my-zsh to ~/pack/

cd ~ || exit 1

tar_gz='ohmyzsh.tar.gz'

tar -zcf "${tar_gz}" .oh-my-zsh

to_dir="${HOME}"/pack
if ! [ -d "${to_dir}" ]; then
    mkdir -p "${to_dir}"
fi

mv "${tar_gz}" "${HOME}"/pack
