#!/usr/bin/env bash

#=tools
#@copy filenames to general pasteboard
#@usage:copy_file_names file1.sh file2.py

#tr -cd "[:print:]":strip out non-printable characters
echo "${@}" | tr -cd "[:print:]" | pbcopy
