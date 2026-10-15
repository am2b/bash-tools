#!/usr/bin/env bash

#=tools
#@在当前目录与~/Downloads之间传递文件

# =====================================================================
# portal.sh — 把文件/目录复制或移动到目标目录（默认 ~/Downloads），同名自动加时间戳
#
# 用法:
#   portal [选项] 文件或目录 [更多文件或目录...]
#
# 选项:
#   -m        移动（默认是复制）；git 仓库内的移动自动改用 git mv
#   -t        打包成 .tar（未压缩）复制过去
#   -z        打包成 .tar.gz（gzip 压缩）复制过去
#   -d PATH   指定"中心目录",普通模式它是目标目录，反向模式它是源目录；反向模式的目标固定是当前目录
#   -b NAME   把多个来源打成一个包（需配合 -t 或 -z）
#   -r        反向送回：默认送到当前目录，可配合 -d 指定目标
#   -f        目标已存在时直接覆盖，不加时间戳
#   -q        安静模式，不打印结果
#   -h        显示帮助
#
# 环境变量:
#   PORTAL_DEST            普通模式下的目标目录（默认 ~/Downloads，-d 优先级更高）
#   PORTAL_TAR_EXCLUDES    覆盖打包排除列表，空格分隔
#
# 例子:
#   portal a.txt                  # 复制 a.txt 到 ~/Downloads/
#   portal -m a.txt b/            # 移动两个条目（git 仓库内自动用 git mv）
#   portal -t 项目/               # 打成 项目.tar（未压缩）复制过去
#   portal -z 项目/               # 打成 项目.tar.gz 复制过去
#   portal -z -m 项目/            # 打成 tar.gz 并删除原目录
#   portal -z -b 项目备份 a.txt b/ c/   # 多个来源打成一个 项目备份.tar.gz
#   portal -d ~/Desktop a.txt     # 复制到 ~/Desktop
#   portal -r ~/Downloads/x.pdf   # 反向：从 Downloads 取回当前目录
#   portal -r -m -z ~/Downloads/项目/   # 反向：打包成 tar.gz 并移动回当前目录
# =====================================================================

set -euo pipefail 2> /dev/null || true # macOS 自带 bash 3.2 不支持 pipefail，容错

# ---------------------------------------------------------------------
# 常量区：脚本默认值
# ---------------------------------------------------------------------
# 普通模式的目标目录（可用 PORTAL_DEST 环境变量或 -d 选项覆盖）
DEFAULT_DEST="${PORTAL_DEST:-$HOME/Downloads}"
# 打包时排除的条目（可用 PORTAL_TAR_EXCLUDES 环境变量整体覆盖）
# 注意：不带 / 的模式按文件名匹配任意层级，如 .git 会排除所有层级下的 .git
EXCLUDES=(.DS_Store .git .svn .hg __pycache__ '*.pyc' '*.pyo')
if [[ -n "${PORTAL_TAR_EXCLUDES:-}" ]]; then
    read -r -a EXCLUDES <<< "$PORTAL_TAR_EXCLUDES"
fi

# ---------------------------------------------------------------------
# 全局状态：由 parse_args 解析命令行后填充
# ---------------------------------------------------------------------
MOVE=0     # 1=移动（默认复制）
TAR_MODE=0 # 1=打包（-t / -z 任一）
GZIP=0     # 1=gzip 压缩（-z）；0=纯 tar（-t）
FORCE=0    # 1=目标已存在时直接覆盖，不加时间戳
QUIET=0    # 1=安静模式，不打印结果
BUNDLE=""  # 非空=把多个来源打成一个包（-b NAME）
REVERSE=0  # 1=反向送回（默认送到当前目录）

TS="" # 一次运行共用的时间戳，批量操作命名一致

DEST=""       # 永远表示中心目录，新增 `TARGET_DIR` 表示实际落盘位置
SOURCES=()    # 待处理的来源列表（parse_args 解析后的剩余参数）
TARGET_DIR="" # 实际落盘目录

# ---------------------------------------------------------------------
# usage — 打印帮助信息
# ---------------------------------------------------------------------
usage() {
    cat << 'EOF'
用法: portal [选项] 文件或目录 [更多...]

把文件/目录复制（默认）或移动到目标目录
普通模式默认送到 ~/Downloads；反向模式（-r）默认送到当前目录
若目标已存在同名条目，自动加时间戳，例如:
  a.txt -> a_2026-10-06_18-59-15.txt

选项:
  -m        移动而不是复制；git 仓库内的移动自动改用 git mv
  -t        打包成 .tar（未压缩）复制过去
  -z        打包成 .tar.gz（gzip 压缩）复制过去
  -d PATH   指定中心目录（普通=目标目录；反向=源目录，默认 ~/Downloads）
  -b NAME   把多个来源打成一个包，需配合 -t 或 -z
  -r        反向送回：从中心目录取回当前目录，相对参数自动前缀中心目录
  -f        目标已存在时直接覆盖，不加时间戳
  -q        安静模式
  -h        显示本帮助

环境变量:
  PORTAL_DEST            普通模式下的目标目录（默认 ~/Downloads，-d 优先级更高）
  PORTAL_TAR_EXCLUDES    覆盖打包排除列表（空格分隔）
EOF
}

# ---------------------------------------------------------------------
# parse_args — 解析命令行选项，结果写入全局状态变量
# 退出：-h 显示帮助后退出 0；用法错误退出 2
# ---------------------------------------------------------------------
parse_args() {
    while getopts ":mtzfqhd:b:r" opt; do
        case "$opt" in
            m) MOVE=1 ;;
            t) TAR_MODE=1 ;;
            z)
                TAR_MODE=1
                GZIP=1
                ;;
            f) FORCE=1 ;;
            q) QUIET=1 ;;
            d) DEST="$OPTARG" ;;
            b) BUNDLE="$OPTARG" ;;
            r) REVERSE=1 ;;
            h)
                usage
                exit 0
                ;;
            *)
                usage >&2
                exit 2
                ;; # 未知选项
        esac
    done
    shift $((OPTIND - 1))
    SOURCES=("$@")

    # 至少需要一个来源
    if [[ ${#SOURCES[@]} -eq 0 ]]; then
        usage >&2
        exit 2
    fi
    # -b 必须配合打包选项，否则无法决定打成 .tar 还是 .tar.gz
    if [[ -n "$BUNDLE" && $TAR_MODE -eq 0 ]]; then
        echo "错误: -b 需要配合 -t（tar）或 -z（tar.gz）使用" >&2
        exit 2
    fi
}

# ---------------------------------------------------------------------
# resolve_dest — 确定目标目录
# 优先级：-d 选项 > 模式默认值（普通=~/Downloads，反向=当前目录 $PWD）
# ---------------------------------------------------------------------
resolve_dest() {
    # DEST：中心目录（普通模式=目标目录，反向模式=源目录）
    if [[ -z "$DEST" ]]; then
        DEST="$DEFAULT_DEST"
    fi
    # TARGET_DIR：实际落盘目录（普通模式=中心目录，反向模式=当前目录）
    if [[ $REVERSE -eq 1 ]]; then
        TARGET_DIR="$PWD"
    else
        TARGET_DIR="$DEST"
    fi
}

#判断顺序是关键：反向模式 + 相对路径（非 `/` 开头、非 `~/` 开头）→ 拼上中心目录；绝对路径和 `~/` 开头原样使用。`${s%/}` 顺带把尾斜杠削掉
resolve_src() {
    local s="$1"
    if [[ $REVERSE -eq 1 && "$s" != /* && "$s" != ~/* ]]; then
        s="$DEST/${s%/}"
    fi
    printf '%s\n' "${s%/}"
}

# ---------------------------------------------------------------------
# log — 打印一行结果（安静模式下静默）
# ---------------------------------------------------------------------
log() {
    [[ $QUIET -eq 1 ]] || printf '%s\n' "$*"
}

# ---------------------------------------------------------------------
# git 工具函数
# ---------------------------------------------------------------------
# git_toplevel — 输出 dir 所在 git 仓库根目录；不在仓库内则输出空
git_toplevel() {
    git -C "$1" rev-parse --show-toplevel 2> /dev/null || true
}

# git_tracked — 判断 parent 目录下名为 name 的文件是否已被 git 跟踪
git_tracked() {
    git -C "$1" ls-files --error-unmatch -- "$2" > /dev/null 2>&1
}

# ---------------------------------------------------------------------
# copy_one — 复制一个文件或目录
# macOS 优先用 ditto（完整保留资源分支/扩展属性/ACL/时间等元数据），
# 其他平台回退 cp -Rp
# ---------------------------------------------------------------------
copy_one() {
    if command -v ditto > /dev/null 2>&1; then
        ditto "$1" "$2"
    else
        cp -Rp "$1" "$2"
    fi
}

# ---------------------------------------------------------------------
# unique_name — 生成目标目录下不冲突的路径
#   1. 目标没有同名条目 -> 直接用原名（不加时间戳）
#   2. 目标已存在 -> 加时间戳  a.txt -> a_2026-10-06_18-59-15.txt
#   3. 同一秒内撞车（一次命令传了两个同名文件）-> 再加 _2/_3...
#   4. 点文件（.zshrc 等）直接在末尾加时间戳，不拆扩展名
#   5. .tar / .tar.gz 作为整体扩展名处理，不拆断
# 参数：$1=基础文件名；输出：唯一的目标路径（依赖全局 DEST / TS）
# ---------------------------------------------------------------------
unique_name() {
    local base="$1" plain="$TARGET_DIR/$1" stem="" ext="" cand n=1
    # 原名空闲则直接使用，这是"只有同名冲突才加时间戳"的核心规则
    if [[ ! -e "$plain" && ! -L "$plain" ]]; then
        printf '%s\n' "$plain"
        return 0
    fi
    # 按文件名形态拆分"主干 + 扩展名"，时间戳插在两者之间
    if [[ "$base" == .* ]]; then
        stem="$base" # 点文件不拆扩展名
    elif [[ "$base" == *.tar.gz ]]; then
        stem="${base%.tar.gz}" # foo.tar.gz -> foo + .tar.gz
        ext=".tar.gz"
    elif [[ "$base" == *.tar ]]; then
        stem="${base%.tar}" # foo.tar -> foo + .tar
        ext=".tar"
    elif [[ "$base" == *.* ]]; then
        stem="${base%.*}"  # a.txt -> a
        ext=".${base##*.}" # a.txt -> .txt
    else
        stem="$base" # 无扩展名
    fi
    cand="$TARGET_DIR/${stem}_${TS}${ext}"
    # 同一秒内多个同名来源时，依次尝试 _1/_2/_3...
    while [[ -e "$cand" || -L "$cand" ]]; do
        cand="$TARGET_DIR/${stem}_${TS}_${n}${ext}"
        n=$((n + 1))
    done
    printf '%s\n' "$cand"
}

# ---------------------------------------------------------------------
# make_tar — 打包成员到目标文件
# 参数：$1=目标文件；其余为 tar 成员参数（-C 父目录 名字...）
# 排除列表由全局 EXCLUDES 决定，压缩与否由全局 GZIP 决定
# ---------------------------------------------------------------------
make_tar() {
    local target="$1"
    shift
    local excl=()
    for pat in "${EXCLUDES[@]}"; do
        excl+=(--exclude="$pat")
    done
    if [[ $GZIP -eq 1 ]]; then
        tar -czf "$target" "${excl[@]}" "$@"
    else
        tar -cf "$target" "${excl[@]}" "$@"
    fi
}

# ---------------------------------------------------------------------
# move_one — git 感知的移动
# 规则：
#   * 源在 git 仓库内、已被 git 跟踪、且目标在同一仓库内 -> 用 git mv
#     （git 会记录 rename，历史可追溯）
#   * 其余情况 -> 普通 mv，并视方向给出 git 状态提示：
#     - 源在仓库内但目标在仓库外（送往 ~/Downloads 等）：
#       git 会把原文件标记为已删除——这是正确语义，文件确实离开了仓库
#     - 源在仓库外、目标在仓库内（反向移入仓库）：
#       git 会显示为未跟踪，如需纳入版本控制请 git add
# 参数：$1=源路径；$2=目标路径
# ---------------------------------------------------------------------
move_one() {
    local src="$1" target="$2"
    local src_parent="" src_root="" target_root=""
    src_parent="$(dirname "$src")"
    src_root="$(git_toplevel "$src_parent")"             # 源所在仓库根（可能为空）
    target_root="$(git_toplevel "$(dirname "$target")")" # 目标所在仓库根（可能为空）

    # 三个条件齐备才用 git mv
    if [[ -n "$src_root" && -n "$target_root" && "$src_root" == "$target_root" ]] &&
        git_tracked "$src_parent" "$(basename "$src")"; then
        if git -C "$src_parent" mv -- "$(basename "$src")" "$target" 2> /dev/null; then
            log "git 移动 $src -> $target"
            return 0
        fi
        # git mv 意外失败（边界情况）时继续往下走普通 mv 兜底
    fi

    # 普通 mv
    mv "$src" "$target" || return 1
    log "移动 $src -> $target"

    # 移动成功后的 git 状态提示（只告知，不改变行为）
    if [[ -n "$src_root" && (-z "$target_root" || "$src_root" != "$target_root") ]]; then
        log "提示: 源在 git 仓库内但目标在仓库外，已用普通 mv，git 会把原文件标记为已删除"
    elif [[ -z "$src_root" && -n "$target_root" ]]; then
        log "提示: 已移入 git 仓库（$target_root），如需跟踪请 git add"
    fi
}

# ---------------------------------------------------------------------
# process_one — 处理单个来源：复制 / 移动 / 打包
# 参数：$1=来源路径（文件或目录）
# ---------------------------------------------------------------------
process_one() {
    local src="$1" name="" parent="" target="" ext=""
    src="$(resolve_src "$src")"          # 反向模式：相对参数自动前缀中心目录
    src="${src%/}"           # 去掉尾部斜杠，basename 更干净
    if [[ -z "$src" ]]; then # 拦截根目录："/" 去尾斜杠后变成空串
        echo "错误: 无效路径: $1" >&2
        return 1
    fi
    if [[ ! -e "$src" && ! -L "$src" ]]; then
        echo "${src}"
        echo "错误: 不存在: $src" >&2
        return 1
    fi
    name="$(basename "$src")"

    if [[ $TAR_MODE -eq 1 ]]; then
        # --- 打包模式：-t 产出 .tar，-z 产出 .tar.gz ---
        ext=".tar.gz"
        [[ $GZIP -eq 1 ]] || ext=".tar"
        target="$(unique_name "${name}${ext}")"
        # tar 时用 -C 进入父目录，包内只保留顶层名字，不带完整路径
        parent="$(cd "$(dirname "$src")" 2> /dev/null && pwd)" || {
            echo "错误: 无法定位 ${src} 的父目录" >&2
            return 1
        }
        if ! make_tar "$target" -C "$parent" -- "$name"; then
            echo "错误: 打包失败: $src" >&2
            return 1
        fi
        log "打包 $src -> $target"
        # 打包 + 移动（-t/-z 与 -m 同用）：打包成功后删除原文件
        if [[ $MOVE -eq 1 ]]; then
            if rm -rf "$src"; then
                log "已删除原文件 $src"
            else
                echo "警告: 打包成功，但删除原文件失败: $src" >&2
            fi
        fi
    else
        # --- 非打包模式：普通复制或移动 ---
        if [[ $FORCE -eq 1 ]]; then
            # 强制覆盖：不加时间戳，直接覆盖目标
            target="$TARGET_DIR/$name"
            if [[ -e "$target" || -L "$target" ]]; then
                log "警告: 目标已存在，-f 强制覆盖: $target"
            fi
        else
            target="$(unique_name "$name")"
        fi
        if [[ $MOVE -eq 1 ]]; then
            move_one "$src" "$target" || return 1 # git 感知移动
        else
            if ! copy_one "$src" "$target"; then
                echo "错误: 复制失败: $src" >&2
                return 1
            fi
            log "复制 $src -> $target"
        fi
    fi
}

# ---------------------------------------------------------------------
# bundle_process — 把多个来源打成一个包（-b NAME 配合 -t/-z）
# 参数：$@=全部来源；包名取自全局 BUNDLE
# 说明：成员用 -C 父目录 + 名字 成对传入，不能加 --（它会终止 tar 的
#       选项解析，导致后续 -C 被当作文件名）；成员名以 - 开头时报错
# ---------------------------------------------------------------------
bundle_process() {
    local target="" ext="" src="" parent="" name="" tarargs=()
    ext=".tar.gz"
    [[ $GZIP -eq 1 ]] || ext=".tar"
    target="$(unique_name "${BUNDLE}${ext}")"

    # 逐个来源收集 (父目录, 名字) 对，构造 tar 成员参数
    for src in "$@"; do
        src="$(resolve_src "$src")"
        src="${src%/}"
        if [[ -z "$src" ]]; then # 拦截根目录："/" 去尾斜杠后变成空串
            echo "错误: 无效路径: $1" >&2
            return 1
        fi
        if [[ ! -e "$src" && ! -L "$src" ]]; then
            echo "错误: 不存在: $src" >&2
            return 1
        fi
        parent="$(cd "$(dirname "$src")" 2> /dev/null && pwd)" || {
            echo "错误: 无法定位 ${src} 的父目录" >&2
            return 1
        }
        name="$(basename "$src")"
        if [[ "$name" == -* ]]; then
            echo "错误: bundle 模式下不支持以 - 开头的文件名: $name" >&2
            return 1
        fi
        tarargs+=(-C "$parent" "$name")
    done

    if ! make_tar "$target" "${tarargs[@]}"; then
        echo "错误: 打包失败" >&2
        return 1
    fi
    log "打包 $# 个来源 -> $target"

    # 打包 + 移动（-b 与 -m 同用）：打包成功后删除全部原文件
    if [[ $MOVE -eq 1 ]]; then
        for src in "$@"; do
            rm -rf "$src" || echo "警告: 删除失败: $src" >&2
        done
        log "已删除全部原文件"
    fi
}

# ---------------------------------------------------------------------
# main — 主流程入口
# ---------------------------------------------------------------------
main() {
    parse_args "$@"
    resolve_dest # 注意：调用函数不加括号，加括号会被 bash 当成函数定义

    # 目标目录必须存在（普通模式 ~/Downloads 一般已存在；-d 指定时自动创建）
    #反向模式确保当前目录存在，语义更准；普通模式两者相等，无影响
    mkdir -p "$TARGET_DIR" || {
        echo "错误: 无法创建目录 $TARGET_DIR" >&2
        exit 1
    }
    # 一次运行共用一个时间戳，批量操作命名保持一致
    TS="$(date +"%Y-%m-%d_%H-%M-%S")"

    local rc=0
    if [[ -n "$BUNDLE" ]]; then
        bundle_process "${SOURCES[@]}" || rc=1
    else
        for src in "${SOURCES[@]}"; do
            echo "${src}"
            echo "---"
            process_one "$src" || rc=1
        done
    fi
    exit "$rc"
}

main "$@"
#（注：内容由AI生成）
