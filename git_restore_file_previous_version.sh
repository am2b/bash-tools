#!/usr/bin/env bash

#=git-restore
#@将某个文件恢复成其"上一个版本"(该文件最近两次改动中,较旧的那次提交里的内容)
#@usage:
#@script.sh <文件路径>        恢复文件内容
#@script.sh -n <文件路径>     dry run
#@script.sh -f <文件路径>     文件有未提交改动时也强制覆盖(默认拒绝并退出)

set -euo pipefail

usage() {
    cat << 'EOF'
用法: script.sh [-f|--force] [-n|--dry-run] <文件路径>

将某个文件恢复成"上一个版本":
即该文件"最近一次修改之前"那次提交里的内容(跨重命名跟随)

选项:
  -f, --force    文件有未提交改动时仍覆盖(默认拒绝并退出)
  -n, --dry-run  只打印将恢复的提交,路径和差异预览,不写文件
  -h, --help     显示本帮助
EOF
}

force=0
dry_run=0
file=""

while [ $# -gt 0 ]; do
    case "$1" in
        -f | --force) force=1 ;;
        -n | --dry-run) dry_run=1 ;;
        -h | --help)
            usage
            exit 0
            ;;
        -*)
            echo "未知选项: $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            [ -z "$file" ] || {
                echo "错误: 只能指定一个文件路径" >&2
                exit 2
            }
            file=$1
            ;;
    esac
    shift
done

if [ -z "$file" ]; then
    echo "错误: 缺少文件路径" >&2
    usage >&2
    exit 2
fi

# ---------- 前置校验 ----------
if [ ! -f "$file" ]; then
    echo "错误: 文件不存在或不是普通文件: $file" >&2
    echo "（若文件已被删除，请直接用 git checkout -- <file> 或 git restore <file>）" >&2
    exit 1
fi

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "错误: 当前目录不在 git 仓库中" >&2
    exit 1
fi

if ! git ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
    echo "错误: 文件未被 git 跟踪: $file" >&2
    exit 1
fi

# ---------- 取最近两次改动该文件的提交 ----------
# first  = 最近一次改动该文件的提交
# second = 上一次改动该文件的提交 = 要恢复到的"上一个版本"
lines=$(git log --follow --format=%H -n 2 -- "$file")
first=$(printf '%s\n' "$lines" | sed -n '1p')
second=$(printf '%s\n' "$lines" | sed -n '2p')

if [ -z "$first" ]; then
    echo "错误: 没有找到该文件的历史提交" >&2
    exit 1
fi
if [ -z "$second" ]; then
    echo "错误: 该文件只有一次改动记录，没有'上一个版本'" >&2
    exit 1
fi

# ---------- 确定"上一个版本"中该文件的路径（处理重命名） ----------
# 多数情况路径没变：直接取 $second:$file。
if git cat-file -e "$second:$file" 2> /dev/null; then
    path_at_second=$file
else
    # 路径变了（例如最近一次改动就是一次重命名）：
    # 从 --name-status 输出中定位第二次改动提交的状态行，还原当时的路径。
    # 状态行格式：R/C 为 "R100\t旧路径\t新路径"（该提交里文件在新路径），
    #            M/A/D 为 "M\t路径"。
    path_at_second=$(
        git log --follow --format=%H --name-status -n 2 -- "$file" |
            awk -v h2="$second" '
        $0 == h2 { in_second = 1; next }
        in_second && /^[AMDRC][0-9]*\t/ {
          n = split($0, f, "\t")
          if (f[1] ~ /^[RC]/) print f[3]; else print f[2]
          exit
        }
      '
    )
    if [ -z "$path_at_second" ]; then
        echo "错误: 无法确定该文件在上一个版本中的路径（可能在上一个版本中被删除）" >&2
        exit 1
    fi
fi

# ---------- dry run ----------
if [ "$dry_run" -eq 1 ]; then
    echo "将把 $file 恢复为提交 $(git rev-parse --short "$second") 中 $path_at_second 的内容"
    echo "--- 差异预览（- 号行恢复后会被删除，+ 号行会被恢复出来）---"
    git show "$second:$path_at_second" | diff -u "$file" - || true
    exit 0
fi

# ---------- 未提交改动检查 ----------
if [ "$force" -ne 1 ]; then
    if ! git diff --quiet -- "$file" || ! git diff --cached --quiet -- "$file"; then
        echo "错误: $file 有未提交的改动（工作区或暂存区）" >&2
        echo "为避免误覆盖，默认拒绝恢复。请先提交/暂存当前改动，或加 --force 强制覆盖。" >&2
        exit 1
    fi
fi

# ---------- 执行恢复 ----------
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
git show "$second:$path_at_second" > "$tmp"
#保留原文件权限(如可执行位),macOS与Linux的stat参数不同
mode=$(stat -c %a "$file" 2> /dev/null || stat -f %Lp "$file")
chmod "$mode" "$tmp"
mv "$tmp" "$file"

echo "已恢复: $file <- 提交 $(git rev-parse --short "$second") 中的 $path_at_second"
echo "下一步: git diff $file 检查效果,确认后 git add $file 暂存"
