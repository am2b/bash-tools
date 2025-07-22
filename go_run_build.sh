#!/usr/bin/env bash

#=go
#@在go项目的任意目录run/build,支持多个'package main'
#@usage:
#@script.sh -h
#@script.sh [--select] [run|build] [Go选项...] [--] [程序参数...]"

usage() {
    echo "用法:"
    echo "$(basename "$0") [--select] [run|build] [Go选项...] [--] [程序参数...]"
    echo
    echo "动作:"
    echo "  run     (默认)运行主包,run之后的参数会传递给Go程序"
    echo "  build   构建主包,输出的可执行文件名与项目名相同"
    echo
    echo "选项:"
    echo "  -h,--help     显示此帮助信息并退出"
    echo "  --select      忽略缓存的main包路径"
    echo
    echo "提示:"
    echo "  如果传递给程序的参数和go run的选项冲突,请用'--'分隔:"
    echo "  示例:$(basename "$0") run -- -flag-for-my-program value"
}

#找到项目的根目录
find_go_mod_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/go.mod" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

#判断参数所代表的目录是否是一个main包
is_main_package() {
    local dir="$1"
    local go_files=("$dir"/*.go)
    if [[ ${#go_files[@]} -eq 1 && -f "${go_files[0]}" && "$(basename "${go_files[0]}")" == "main.go" ]]; then
        return 0
    fi
    #查找package main
    grep -Eq '^[[:space:]]*package[[:space:]]+main[[:space:]]*$' "$dir"/*.go 2>/dev/null
}

#扫描项目根目录下常见的main包位置
#返回找到的所有main包的相对路径
scan_main_packages() {
    local root_dir="$1"
    local found_paths=()

    local common_main_dirs=(
        #main.go可能会在项目的根目录下
        "."
        #cmd/*会匹配cmd目录下的:
        #1,一级子目录
        #2,一级文件
        #3,符号链接
        #4,甚至匹配cmd/*自己(如果没匹配到任何东西时,bash会原样返回字符串cmd/*):
        #当cmd/目录下是空的时:
        #for dir in cmd/*; do
        #    echo "$dir"
        #done
        #会输出:
        #cmd/*
        #直接把模式本身当作字符串传给for了
        "cmd/*"
        "app/*"
        "src/*"
    )

    for pattern in "${common_main_dirs[@]}"; do
        #bash的路径通配符(globbing)只有在未被引号包裹时才会展开
        #$root_dir 用引号包起来是对的(防止路径里有空格),但/$pattern不能加引号,否则*就失效了
        for dir in "$root_dir"/$pattern; do
            #如果dir不是目录,则跳过当前循环
            [[ -d "$dir" ]] || continue
            #如果dir是一个main包
            if is_main_package "$dir"; then
                #去掉根目录前缀
                local rel_path="${dir#"$root_dir"/}"
                found_paths+=("$rel_path")
            fi
        done
    done

    #输出找到的所有main包的相对路径(每个路径之间用空格分隔)
    echo "${found_paths[@]}"
}

#查找并确定最终要运行或构建的main包路径
#返回被选择的main包的相对路径
find_main_package_path() {
    local root_dir="$1"
    local force_select="$2"
    local cache_file="$root_dir/.goexec_cache"

    #优先用缓存中的路径
    if [[ -f "$cache_file" && "$force_select" != "1" ]]; then
        local cached_path
        cached_path=$(cat "$cache_file")
        if [[ -n "$cached_path" && -d "$root_dir/$cached_path" ]] && is_main_package "$root_dir/$cached_path"; then
            echo "$cached_path"
            return 0
        fi
    fi

    #收集所有可能的main包相对路径
    local found_paths=()
    mapfile -t found_paths < <(scan_main_packages "$root_dir")
    local num_found=${#found_paths[@]}

    #如果只找到一个main包
    if [[ "$num_found" -eq 1 ]]; then
        #返回main包的相对路径,并且将其写入到缓存文件
        echo "${found_paths[0]}" | tee "$cache_file"
        return 0
    fi

    #如果找到了多个main包,则让用户选择
    if [[ "$num_found" -gt 1 ]]; then
        local selected
        if command -v fzf >/dev/null 2>&1; then
            selected=$(printf "%s\n" "${found_paths[@]}" | fzf --prompt "选择要运行的main包 > ")
        else
            echo "发现多个main包路径,请选择一个(输入序号):" >&2
            for i in "${!found_paths[@]}"; do
                echo "  $((i + 1)). ${found_paths[$i]}" >&2
            done
            read -r -p "选择(默认:1):" choice_num
            choice_num=${choice_num:-1}
            if [[ "$choice_num" =~ ^[0-9]+$ ]] && ((choice_num > 0 && choice_num <= num_found)); then
                selected="${found_paths[$((choice_num - 1))]}"
            else
                echo "无效选择" >&2
                return 1
            fi
        fi

        if [[ -n "$selected" ]]; then
            echo "$selected" | tee "$cache_file"
            return 0
        fi
    fi

    echo "未在常规位置找到'package main',请检查项目的目录结构" >&2
    return 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

#解析--select
force_select=0
if [[ "$1" == "--select" ]]; then
    force_select=1
    shift
fi

#项目的根目录
root_dir=$(find_go_mod_root)
if [[ -z "$root_dir" ]]; then
    echo "错误:没有找到go.mod,请确保是在一个Go项目里执行该脚本"
    exit 1
fi
cd "$root_dir" || exit 1

#main包的相对路径
main_package_path=$(find_main_package_path "$root_dir" "$force_select")
if [[ -z "$main_package_path" ]]; then
    echo "错误:没有找到main包"
    exit 1
fi

#run/build(默认:run)
action=${1:-run}
if [[ "$action" == "run" || "$action" == "build" ]]; then
    shift
fi

#可执行文件名(默认是项目根目录的名称)
executable_name=$(basename "$root_dir")

if [[ "$action" == "run" ]]; then
    #echo "运行:go run ./$main_package_path $*"
    #"$@"会将脚本接收到的所有剩余参数(Go选项和程序参数)原样传递给go run
    go run "./$main_package_path" "$@"
elif [[ "$action" == "build" ]]; then
    #echo "执行:go build -o $executable_name ./$main_package_path $*"
    go build -o "$executable_name" "./$main_package_path" "$@"
else
    echo "错误:未知动作:$action(只支持run或build)"
    usage
    exit 1
fi
