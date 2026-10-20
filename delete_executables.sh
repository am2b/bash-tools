#!/usr/bin/env bash

#=tools
#@删除当前目录下的可执行文件(普通文件且拥有可执行权限(execute bit))
#@usage:
#@script.sh                仅当前目录(不递归),先预览再确认
#@script.sh --recursive    递归删除所有子目录下的可执行文件
#@script.sh --dry-run      仅预览,不实际删除
#@script.sh --yes          跳过确认,直接删除
#@script.sh --help         查看帮助

set -euo pipefail

RECURSE=0
DRY_RUN=0
YES=0

usage() {
    echo "delete_executables.sh [--recursive/--dry-run/--yes/--help]"
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --recursive | -r) RECURSE=1 ;;
        --dry-run | -n) DRY_RUN=1 ;;
        --yes | -y) YES=1 ;;
        --help | -h) usage ;;
        *)
            echo "未知参数: $arg (可用 --help 查看用法)" >&2
            exit 2
            ;;
    esac
done

#构造find命令:默认仅当前目录(maxdepth1),--recursive则全递归
if [ "$RECURSE" = "1" ]; then
    find_cmd=(find . -type f -executable)
else
    find_cmd=(find . -maxdepth 1 -type f -executable)
fi

#生成预览清单
mapfile -t files < <("${find_cmd[@]}" 2> /dev/null)
count=${#files[@]}

echo "发现 $count 个可执行文件："
for f in "${files[@]}"; do
    [ -n "$f" ] && echo "  $f"
done

if [ "$count" -eq 0 ]; then
    echo "没有需要删除的可执行文件。"
    exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] 仅预览，未删除任何文件。"
    exit 0
fi

if [ "$YES" = "0" ]; then
    read -r -p "确认删除以上 $count 个文件? 输入 yes 继续: " ans
    [ "$ans" = "yes" ] || {
        echo "已取消。"
        exit 1
    }
fi

"${find_cmd[@]}" -delete
echo "已删除 $count 个可执行文件。"
