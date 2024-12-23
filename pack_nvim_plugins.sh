#!/usr/bin/env bash

#=pack
#@pack the dir of ~/.local/share/nvim/lazy/ to ~/pack/

cd ~/.local/share/nvim/ || exit 1

tar -zcf lazy.tar.gz lazy

to_dir="${HOME}"/pack
if ! [ -d "${to_dir}" ]; then
    mkdir -p "${to_dir}"
fi

mv lazy.tar.gz "${to_dir}"

cd ~ || exit 1
