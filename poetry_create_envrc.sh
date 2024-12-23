#!/usr/bin/env bash

#=python
#@create .envrc in the current directory(created by poetry) for direnv

#'EOF':do not interpret variables in the text,then use single quotes
cat << 'EOF' > .envrc
export VIRTUAL_ENV=$(poetry env info --path)
layout python $VIRTUAL_ENV/bin/python
EOF
