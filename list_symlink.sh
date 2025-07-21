#!/usr/bin/env bash

#=tools
#@list symbolic link
#@usage:
#@list all symbolic link:
#@script.sh [--all] [path]
#@list non-hidden symbolic link:
#@script.sh --non-hidden [path]
#@list hidden symbolic link:
#@script.sh --hidden [path]

#如果脚本中的任何命令以非零状态码退出(表示失败),脚本会立即终止
set -e

usage() {
    echo "用法:$(basename "${0}") [--all | --hidden | --non-hidden] [路径]"
    echo
    echo "选项:"
    echo "--all         显示所有软链接(默认)"
    echo "--hidden      仅显示隐藏的软链接(以.开头)"
    echo "--non-hidden  仅显示非隐藏的软链接"
    echo "路径          指定目录(默认当前目录)"
    exit 1
}

MODE="all"
TARGET_DIR="."

# 解析参数
for arg in "$@"; do
    case "$arg" in
    --all)
        MODE="all"
        ;;
    --hidden)
        MODE="hidden"
        ;;
    --non-hidden)
        MODE="non-hidden"
        ;;
    -h | --help)
        usage
        ;;
    -*)
        echo "未知选项:$arg"
        usage
        ;;
    *)
        TARGET_DIR="$arg"
        ;;
    esac
done

# 确保目录存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误:目录不存在:$TARGET_DIR"
    exit 1
fi

# 找出匹配的符号链接
case "$MODE" in
all)
    LINKS=$(find "$TARGET_DIR" -maxdepth 1 -type l)
    ;;
hidden)
    LINKS=$(find "$TARGET_DIR" -maxdepth 1 -type l -name '.*')
    ;;
non-hidden)
    LINKS=$(find "$TARGET_DIR" -maxdepth 1 -type l ! -name '.*')
    ;;
esac

# 打印链接和目标
for link in $LINKS; do
    if target=$(readlink "$link"); then
        # 去掉./前缀
        link_display="${link#./}"

        # 将目标路径中以$HOME开头的部分替换为~
        if [[ "$target" == "$HOME"* ]]; then
            target_display="~${target#$HOME}"
        else
            target_display="$target"
        fi

        # 打印美化后的内容
        echo "$link_display -> $target_display"
    else
        echo "$link -> [无法解析目标]"
    fi
done
