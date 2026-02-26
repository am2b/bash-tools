#!/usr/bin/env bash

#=pack
#@pack the dir of ~/.local/share/nvim/mason/packages/ to ~/pack/
#@现在没有使用mason

cd ~/.local/share/nvim/mason/ || exit 1

tar -zcf packages.tar.gz packages

to_dir="${HOME}"/pack
if ! [ -d "${to_dir}" ]; then
    mkdir -p "${to_dir}"
fi

mv packages.tar.gz "${to_dir}"

cd ~ || exit 1
