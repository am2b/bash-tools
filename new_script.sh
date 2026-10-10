#!/usr/bin/env bash

#=tools
#@create a new script

set -euo pipefail

params_size="$#"

if ((params_size == 0)) || ((params_size > 2)); then
    echo "error: 需要1或2个参数script.sh or script sh" >&2
    exit 1
fi

script_name="${1}"
if ((params_size == 2)); then
    script_name="${1}"."${2}"
fi

if [ -e "${script_name}" ]; then
    echo "error: '${script_name}' already exists" >&2
    exit 1
fi

if ! touch "${script_name}"; then
    echo "error: 无法创建 '${script_name}' (权限不足或父目录不存在?)" >&2
    exit 1
fi

if ! chmod 755 "${script_name}"; then
    echo "error: 无法设置权限" >&2
    exit 1
fi

editor="${EDITOR:-nvim}"
if ! command -v "$editor" &> /dev/null; then
    echo "error: 编辑器 '$editor' 未安装 (可设置 \$EDITOR 环境变量)" >&2
    exit 1
fi
"$editor" "${script_name}"
