#!/usr/bin/env bash

#=pack
#@批量解压目录下所有.7z压缩包(不递归)
#@每个压缩包解压到:a:目标目录/下(默认,不会保留压缩包里面的目录结构),b:目标目录/<压缩包同名文件夹>/下
#@usage:
#@script.sh <源目录> <目标目录> '密码'
#@-s:每个压缩包解压到:目标目录/<压缩包同名文件夹>/下
#@script.sh -s <源目录> <目标目录> '密码'

# 每个压缩包解压到:目标目录/下
flat=true

usage() {
    local script
    script=$(basename "$0")
    echo "批量解压目录下所有.7z压缩包(不递归)"
    echo "每个压缩包解压到:a:目标目录/下(默认,不会保留压缩包里面的目录结构),b:目标目录/<压缩包同名文件夹>/下"
    echo "usage:" >&2
    echo "a:"
    echo "$script source_dir dest_dir 'password'" >&2
    echo "b:"
    echo "$script -s source_dir dest_dir 'password'" >&2
    exit "${1:-1}"
}

check_dependent_tools() {
    local missing=()
    for tool in "${@}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing+=("$tool")
        fi
    done

    if ((${#missing[@]})); then
        echo "error:missing required tool(s):${missing[*]}" >&2
        exit 1
    fi
}

check_envs() {
    if (("$#" == 0)); then
        return 0
    fi

    for var in "$@"; do
        #如果变量未导出或值为空
        if [ -z "$(printenv "$var" 2> /dev/null)" ]; then
            echo "error:this script uses unexported environment variables:${var}"
            return 1
        fi
    done

    return 0
}

check_parameters() {
    if (("$#" != 3)); then
        usage
    fi
}

process_opts() {
    while getopts ":hs" opt; do
        case "$opt" in
            h)
                usage 0
                ;;
            s)
                flat=false
                ;;
            \?)
                echo "error:unsupported option -$OPTARG" >&2
                usage
                ;;
            :)
                echo "error:option -$OPTARG requires an argument" >&2
                usage
                ;;
            *)
                usage
                ;;
        esac
    done
}

main() {
    REQUIRED_TOOLS=(7zz)
    check_dependent_tools "${REQUIRED_TOOLS[@]}"
    REQUIRED_ENVS=()
    check_envs "${REQUIRED_ENVS[@]}" || exit 1
    process_opts "${@}"
    shift $((OPTIND - 1))
    check_parameters "${@}"

    SRC_DIR="$1"
    DST_DIR="$2"
    PASSWORD="$3"

    # ---------- 定位 7z 可执行文件 ----------
    SEVEN_ZIP=""
    for candidate in 7z 7za 7zz; do
        if command -v "$candidate" > /dev/null 2>&1; then
            SEVEN_ZIP="$candidate"
            break
        fi
    done
    if [ -z "$SEVEN_ZIP" ]; then
        echo "错误: 未找到 7z / 7za / 7zz" >&2
        exit 1
    fi

    # ---------- 校验源目录 ----------
    if [ ! -d "$SRC_DIR" ]; then
        echo "错误: 源目录不存在或不是目录: $SRC_DIR" >&2
        exit 1
    fi

    # ---------- 创建目标目录 ----------
    if ! mkdir -p "$DST_DIR"; then
        echo "错误: 无法创建目标目录: $DST_DIR" >&2
        exit 1
    fi

    # 统一去掉结尾的斜杠，方便拼接路径
    SRC_DIR="${SRC_DIR%/}"
    DST_DIR="${DST_DIR%/}"

    # ---------- 收集压缩包列表(按文件名排序,兼容含空格的文件名) ----------
    # 用while read处理,避免空格/换行带来的分词问题
    ARCHIVES=()
    while IFS= read -r -d '' f; do
        ARCHIVES+=("$f")
    done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -iname '*.7z' \) -print0 | sort -z)

    TOTAL="${#ARCHIVES[@]}"

    if [ "$TOTAL" -eq 0 ]; then
        echo "在目录 $SRC_DIR 下没有找到任何 .7z 文件。"
        exit 0
    fi

    echo "=================================================="
    echo "源目录  : $SRC_DIR"
    echo "目标目录: $DST_DIR"
    echo "7z 程序 : $SEVEN_ZIP"
    echo "CPU 核心: $(getconf _NPROCESSORS_ONLN 2> /dev/null || echo '未知')"
    echo "压缩包数: $TOTAL"
    echo "=================================================="
    echo

    # ---------- 逐个解压 ----------
    OK_COUNT=0
    FAIL_COUNT=0
    FAILED_LIST=()

    idx=0
    # 收集每个压缩包解压后的子目录名,为flat做准备
    self_dirs=()
    for archive in "${ARCHIVES[@]}"; do
        idx=$((idx + 1))

        # 压缩包主名(不含.7z 后缀),用作输出子目录名
        base="$(basename "$archive")"
        name="${base%.*}"
        out_dir="$DST_DIR/$name"
        self_dirs+=("${out_dir}")

        echo "--------------------------------------------------"
        echo "[$idx/$TOTAL] 正在解压: $base"
        echo "        输出到: $out_dir"

        mkdir -p "$out_dir"

        # -mmt:利用多核CPU(7zz默认打开)
        # -y:‌对所有提示自动回答Yes(应该不存在解压时文件覆盖的情况,因为不会将完全同名的文件打包在同一个7z包里面)
        # -o和输出路径之间可以没有空格
        if "$SEVEN_ZIP" x "$archive" -p"$PASSWORD" -y -o"$out_dir"; then
            echo "[$idx/$TOTAL] 完成: $base"
            OK_COUNT=$((OK_COUNT + 1))
        else
            echo "[$idx/$TOTAL] 失败: $base  （可能是密码错误、文件损坏或磁盘空间不足）" >&2
            FAIL_COUNT=$((FAIL_COUNT + 1))
            FAILED_LIST+=("$base")
        fi
        echo
    done

    # ---------- 汇总 ----------
    echo "=================================================="
    echo "全部处理完毕。成功: $OK_COUNT  失败: $FAIL_COUNT  总计: $TOTAL"
    if [ "$FAIL_COUNT" -gt 0 ]; then
        echo "以下文件未能成功解压:"
        for f in "${FAILED_LIST[@]}"; do
            echo "  - $f"
        done
        exit 2
    fi
    echo "全部解压成功。"
    echo

    counter=0
    if [[ "${flat}" == "true" ]]; then
        echo "开始移动所有文件到${DST_DIR}"
        for d in "${self_dirs[@]}"; do
            # 遍历当前子目录里面的所有文件
            while IFS= read -r -d '' f; do
                base=$(basename "${f}")
                file="${DST_DIR}/${base}"
                # 检查文件名是否冲突
                if [[ -f "${file}" ]]; then
                    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

                    if [[ "$file" == *.* ]]; then
                        file="${file%.*}_${TIMESTAMP}.${file##*.}"
                    else
                        file="${file}_${TIMESTAMP}"
                    fi

                    counter=$((counter + 1))
                fi

                mv "${f}" "${file}"
            done < <(find "${d}" -type f -print0)
        done

        # 删除空目录
        find "${DST_DIR}" -depth -type d -empty -exec rmdir {} \;

        echo "全部移动完成。"
        if ((counter != 0)); then
            echo "遇到${counter}个文件名冲突，已添加后缀"
        fi
    fi

    exit 0
}

main "${@}"
