#!/usr/bin/env bash

#=tools
#@判断两个目录是否相同
#@usage:
#@script.sh dir_1 dir2

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script dir_1 dir_2"
    exit 1
}

process_opts() {
    while getopts ":h" opt; do
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
}

check_parameters() {
    if (("$#" != 2)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local DIR1="$1"
    local DIR2="$2"

    if [ ! -d "$DIR1" ]; then
        echo "error:目录 '$DIR1' 不存在或不是一个目录"
        exit 1
    fi

    if [ ! -d "$DIR2" ]; then
        echo "error:目录 '$DIR2' 不存在或不是一个目录"
        exit 1
    fi

    #建立临时文件存放各自的文件列表(使用相对路径)
    local TMP1
    local TMP2
    local DIFF_FILE
    TMP1=$(mktemp)
    TMP2=$(mktemp)
    DIFF_FILE=$(mktemp)

    #忽略的文件和目录数组
    IGNORE_FILES=(
        '.DS_Store'
        #'Thumbs.db'
        #'.git'
    )

    local exclude_args=()
    for ignore in "${IGNORE_FILES[@]}"; do
        exclude_args+=(! -name "$ignore")
    done

    pushd "$DIR1" >/dev/null || exit 1
    find . -type f "${exclude_args[@]}" | sort >"$TMP1"
    popd >/dev/null || exit 1

    pushd "$DIR2" >/dev/null || exit 1
    find . -type f "${exclude_args[@]}" | sort >"$TMP2"
    popd >/dev/null || exit 1

    #1.处理只存在于$DIR1中的文件
    while read -r file; do
        echo "Only in $DIR1:$file" >>"$DIFF_FILE"
    done < <(comm -23 "$TMP1" "$TMP2")

    #2.处理只存在于$DIR2中的文件
    while read -r file; do
        echo "Only in $DIR2:$file" >>"$DIFF_FILE"
    done < <(comm -13 "$TMP1" "$TMP2")

    #添加一行分隔符
    if [[ -s "${DIFF_FILE}" ]]; then
        echo "====================" >>"${DIFF_FILE}"
    fi

    #3.对于两个目录都有的文件,比较sha256sum是否一致
    while read -r file; do
        local file1 file2
        local sum1 sum2
        #${var#pattern}是bash的字符串操作,用于删除变量var中开头匹配pattern的部分
        file1="$DIR1/${file#./}"
        file2="$DIR2/${file#./}"
        sum1=$(sha256sum "$file1" | awk '{print $1}')
        sum2=$(sha256sum "$file2" | awk '{print $1}')
        if [ "$sum1" != "$sum2" ]; then
            #获取修改时间
            local mod1 mod2
            local time1 time2
            mod1=$(stat -c %Y "$file1")
            mod2=$(stat -c %Y "$file2")
            time1=$(stat -c %y "$file1")
            time2=$(stat -c %y "$file2")

            if [ "$mod1" -gt "$mod2" ]; then
                echo "File updated in $DIR1:$file" >>"$DIFF_FILE"
                #.013793449 纳秒 = 13 毫秒 + 793 微秒 + 449 纳秒
                #+0800 表示 UTC+8
                echo "    $DIR1:SHA256=$sum1,Modified:$time1" >>"$DIFF_FILE"
                echo "    $DIR2:SHA256=$sum2,Modified:$time2" >>"$DIFF_FILE"
                echo >>"${DIFF_FILE}"
            elif [ "$mod2" -gt "$mod1" ]; then
                echo "File updated in $DIR2:$file" >>"$DIFF_FILE"
                echo "    $DIR2:SHA256=$sum2,Modified:$time2" >>"$DIFF_FILE"
                echo "    $DIR1:SHA256=$sum1,Modified:$time1" >>"$DIFF_FILE"
                echo >>"${DIFF_FILE}"
            else
                echo "File differs (same modification time) in both directories:$file" >>"$DIFF_FILE"
                echo "    $DIR1:SHA256=$sum1,Modified:$time1" >>"$DIFF_FILE"
                echo "    $DIR2:SHA256=$sum2,Modified:$time2" >>"$DIFF_FILE"
                echo >>"${DIFF_FILE}"
            fi
        fi
    done < <(comm -12 "$TMP1" "$TMP2")

    if [ -s "$DIFF_FILE" ]; then
        echo "两个目录不一致,差异明细如下:"
        #删除掉DIFF_FILE末尾的空行(如果有的话)
        sed -i -e 's/[[:space:]]*$//' "${DIFF_FILE}"
        sed -i -e :a -e '/^$/{$d;N;ba' -e '}' "${DIFF_FILE}"

        cat "$DIFF_FILE"
    else
        echo "两个目录完全一致"
    fi

    rm "$TMP1" "$TMP2" "$DIFF_FILE"
}

main "${@}"
