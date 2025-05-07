#!/usr/bin/env bash

#=tools
#@如果iina的截图文件名称存在不连续的"坑洞"的话,重新命名,并且保证顺序性
#@请确保iina的截图目录下仅存在"一集"的截图,无法适配同时存在"多集"截图的情况
#@默认处理png格式的截图(iina截图默认)
#@确保文件名中至少包含一个'-'符号(iina截图默认)
#@最后一个'-'后的部分必须是纯数字(允许前导零)(iina截图默认)
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
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
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    #iina截图的文件名后缀:默认就是小写的png
    file_extension="png"

    cd "${IINA_SCREENSHOT_PATH}" || exit 1

    # 按文件名最后一个"-"后的数字排序文件
    files=()
    while IFS= read -r line; do
        files+=("$line")
    done < <(
        ls "$IINA_SCREENSHOT_PATH"/*."$file_extension" | awk -F'-' -v ext=".$file_extension" '{
            # 提取最后一个字段的数字部分(兼容扩展名)
            split($NF, parts, ext);
            number = parts[1];
            # 输出 "数字 文件名" 用于排序
            printf "%s\t%s\n", number, $0
        }' | sort -n | cut -f2-
    )
    #ls 列出文件 → awk 提取排序键 → sort 按数值排序 → cut 移除临时列
    #1:列出目标文件
    #ls "$IINA_SCREENSHOT_PATH"/*."$file_extension"
    #2:提取排序键
    #$NF 表示最后一个字段
    #split($NF, parts, ext):移除扩展名,比如0003.png按扩展名分割:
    #parts[1] = "0003"   #数字部分
    #parts[2] = ""       #扩展名被移除
    #生成格式为 数字\t文件名 的输出
    #3:排序
    #sort -n:根据第一列(提取的数字)进行数值排序
    #4:移除临时列
    #cut -f2-:删除第一列(数字),仅保留文件名
    #-f2-:表示保留从第二列开始到行尾的所有字段


    # 初始化编号
    counter=1

    # 遍历所有文件
    for file in "${files[@]}"; do
        filename=$(basename "$file")

        # 提取最后一个"-"后的数字部分(保留前导零)
        current_number_str=$(echo "$filename" | awk -F'-' '{ sub(/\..*$/, "", $NF); print $NF }')
        # sub(/\..*$/, "", $NF):对最后一个字段 $NF 执行正则替换操作
        # \..*:匹配从第一个.开始到字段末尾的所有字符(即扩展名部分)
        # print $N:输出修改后的最后一个字段(即已移除扩展名的数字部分)

        prefix=$(echo "$filename" | sed "s/-${current_number_str}.*$//")

        # 计算数字的位数
        num_length=${#current_number_str}

        # 生成补零编号
        expected_number=$(printf "%0${num_length}d" "$counter")

        # 仅当编号不连续时执行重命名
        if [[ "$current_number_str" != "$expected_number" ]]; then
            new_filename="${prefix}-${expected_number}.${file_extension}"
            echo "重命名:$filename → $new_filename"
            mv "$file" "$new_filename"
        fi

        ((counter++))
    done

}

main "${@}"
