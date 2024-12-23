#!/bin/bash

#=install
#@安装perl的常用库

cpan_install="cpanm --quiet --prompt"
cpan_install_notest="cpanm --quiet --prompt --notest"

$cpan_install PLS
$cpan_install utf8::all
$cpan_install Path::ExpandTilde
$cpan_install Path::Class
$cpan_install File::chmod
$cpan_install String::Util
$cpan_install Moose
$cpan_install MooseX::Types::Path::Class
$cpan_install App::cpanminus
$cpan_install_notest Neovim::Ext
