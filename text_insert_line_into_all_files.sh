#!/usr/bin/env bash

#=text
#@给当前目录下的所有文本文件插入一行
#@usage:
#@script.sh 1 "插入第一行的内容"
#@script.sh $ "插入最后一行的内容"

# 检查参数是否足够
if [ "$#" -ne 2 ]; then
    exit 1
fi

# 获取参数
LINE_NUMBER="$1"
INSERT_TEXT="$2
"

# 处理省略单引号的$
if [ "$LINE_NUMBER" == "\$" ] || [ "$LINE_NUMBER" == "$" ]; then
    LINE_NUMBER='$'
fi

# 判断是否是最后一行
if [ "$LINE_NUMBER" == '$' ]; then
    SED_COMMAND="${LINE_NUMBER}a\\
$INSERT_TEXT"
else
    SED_COMMAND="${LINE_NUMBER}i\\
$INSERT_TEXT"
fi

# 遍历当前目录下的所有普通文本文件
for file in *; do
    if [ -f "$file" ]; then
        # 判断是否为普通文本文件
        if file "$file" | grep -q 'text'; then
            sed -i "$SED_COMMAND" "$file"
        fi
    fi
done
