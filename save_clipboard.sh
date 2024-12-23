#!/usr/bin/env bash

#=tools
#@saves the content of the clipboard to a specified directory
#@it can handle both text and image data
#@必须是文字或图像内容直接在剪贴板上,不能说通过cmd+c来拷贝一个文本文件或图像文件在剪贴板上,然后再去运行该脚本
#@requirements:
#@macos:brew install pngpaste
#@linux:xclip imagemagick
#@usage:
#@script.sh
#@script.sh /directory/to/save/

usage() {
    local script
    script=$(basename "$0")

    echo "usage:"
    echo "$script -> save to /tmp/clipboard/"
    echo "$script /directory/to/save/"

    exit 0
}

if (($# > 1)); then
    usage
fi

if (($# == 1)); then
    if [[ ! -d "${1}" ]]; then
        usage
    fi
fi

while getopts "h" opt; do
    case $opt in
    h)
        usage
        ;;
    *)
        echo "error:unsupported option -$opt"
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

# 保存的目录
SAVE_DIR=${1:-"/tmp/clipboard"}

# 确保目录存在
mkdir -p "$SAVE_DIR"

# 获取当前系统类型
OS="$(uname)"

# 保存文本的函数
save_text() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    TEXT_FILE="$SAVE_DIR/text_$TIMESTAMP.txt"

    if [[ "$OS" == "Darwin" ]]; then
        pbpaste >"$TEXT_FILE"
    elif [[ "$OS" == "Linux" ]]; then
        if command -v xclip &>/dev/null; then
            xclip -o >"$TEXT_FILE"
        elif command -v xsel &>/dev/null; then
            xsel --output >"$TEXT_FILE"
        else
            echo "xclip or xsel is required on Linux"
            exit 1
        fi
    fi

    echo "Text saved at: $TEXT_FILE"
}

# 保存图片的函数
save_image() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    IMAGE_FILE="$SAVE_DIR/image_$TIMESTAMP.jpeg"

    if [[ "$OS" == "Darwin" ]]; then
        # 需要安装 pngpaste，确保它存在
        if command -v pngpaste &>/dev/null; then
            pngpaste "$IMAGE_FILE"
        else
            echo "pngpaste is required on macOS"
            exit 1
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if command -v xclip &>/dev/null; then
            xclip -selection clipboard -t image/png -o >"$IMAGE_FILE"
        elif command -v wl-paste &>/dev/null; then
            wl-paste --type image/png >"$IMAGE_FILE"
        else
            echo "xclip or wl-paste is required on Linux"
            exit 1
        fi
    fi

    echo "Image saved at: $IMAGE_FILE"
}

# 检查剪贴板是否包含文本
if [[ "$OS" == "Darwin" ]]; then
    TEXT=$(pbpaste)
elif [[ "$OS" == "Linux" ]]; then
    TEXT=$(xclip -o 2>/dev/null || xsel --output 2>/dev/null)
fi

# 如果剪贴板包含文本，保存为文本文件
if [[ -n "$TEXT" ]]; then
    save_text
    exit 0
fi

# 否则，检查是否有图片
if save_image; then
    exit 0
fi

# 如果都没有，打印消息
echo "Clipboard does not contain an image or text."
