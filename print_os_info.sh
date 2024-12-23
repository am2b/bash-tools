#!/usr/bin/env bash

#=convenient
#@print os info

case $(uname -s | tr '[:upper:]' '[:lower:]') in
    "darwin")
        os="mac";;
    "linux")
        os="linux";;
    *)
        os="unknown":$(uname -s);;
esac

echo "os:${os}"
