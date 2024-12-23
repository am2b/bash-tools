#!/usr/bin/env bash

#=python
#@create .envrc in the current directory for direnv

#'EOF':do not interpret variables in the text,then use single quotes
cat << 'EOF' > .envrc
export VIRTUAL_ENV=.venv
layout python

#auto upgrade pip in virtual environment
ver=$(python -m pip -V | awk '{print $2}')
ver1=$(echo "${ver}" | awk 'BEGIN {FS="."} {print $1}')
ver2=$(echo "${ver}" | awk 'BEGIN {FS="."} {print $2}')
ver="${ver1}"."${ver2}"
ret=$(echo dummy | awk -v pip_ver="${ver}" '{if (pip_ver < 24.0) {print 0} else {print 1}}')
if (( "${ret}" == 0 )); then
    python -m pip install --upgrade pip
fi
EOF
