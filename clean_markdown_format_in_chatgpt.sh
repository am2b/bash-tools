#!/usr/bin/env bash

#=convenient
#@clean up the markdown format in chatgpt
#@usage:
#@script.sh file
#@pbpaste | script.sh | pbcopy

#如果提供了文件路径,读取文件内容,否则从标准输入读取
if [[ -n "$1" ]]; then
    input="$1"
else
    input="/dev/stdin"
fi

#数据来源于管道
if [[ -p /dev/stdin ]]; then
    source=1
else
    #数据来源于文件
    if [[ -f "$1" ]]; then
        source=0
    else
        echo "$1 不是一个有效的文件"
        exit 1
    fi
fi

#创建一个临时文件来存储处理后的内容
#mktemp 是一个命令行工具，用于在/tmp创建临时文件或临时目录。它会生成一个唯一的文件名
#$(...) 是命令替换的语法，它允许你在命令中执行另一个命令，并将其输出结果作为字符串返回
temp_file=$(mktemp)

#逐行读取输入文件
#while IFS= read -r line; do 是一种常用的读取文件行的方式，能够安全地处理文件内容，保持原有格式，并避免特殊字符的干扰
#IFS 是一个环境变量，代表内部字段分隔符（Internal Field Separator）
#默认情况下，IFS 的值通常是空格、制表符和换行符。这些字符用于分隔输入行中的字段
#在这里，将 IFS 设置为空（IFS=）意味着在读取行时，不会去除前导或尾随的空白字符，这样可以保持行的原始格式
#read 命令用于从标准输入读取一行
#-r 选项告诉 read 不要处理反斜杠（\）作为转义字符。这样可以确保行中的所有字符，包括反斜杠，都会被正常读取，不会被误解释

#当通过管道输入时(例如pbpaste),输入流可能不会在最后一行附加换行符
#如果输入内容的最后一行没有换行符,read会忽略该行,导致最后一行未被处理
#方法1:
#可以修改输入源,确保输入内容的最后一行始终包含换行符:
#pbpaste | { cat; echo; } | script.sh | pbcopy
#{ cat; echo; }:通过在cat的输出后附加一个空行,确保输入流以换行符结尾
#方法2:
#|| [[ -n "$line" ]]
#这部分确保即使最后一行没有换行符(导致read返回非零状态),也会将其正常处理
while IFS= read -r line || [[ -n "$line" ]]; do
    # 检查是否匹配 "```bash"，如果匹配则跳过该行
    if [[ "$line" == '```bash' ]]; then
        continue
    fi

    # 检查是否匹配 "```"，如果匹配则跳过该行
    if [[ "$line" == '```' ]]; then
        continue
    fi

    #删除变量line 中所有的反引号（`）字符
    #这行代码使用了 Bash 的字符串替换功能。具体语法为：
    #${变量名//模式/替换}
    #其中：
    #变量名 是要进行替换的字符串变量
    #模式 是要匹配的字符串，可以是单个字符、字符串或模式（使用通配符）
    #替换 是用来替代匹配到的字符串的内容
    #// 表示全局替换，即替换行中所有匹配的字符
    #\` 是反引号字符，由于反引号在 Bash 中有特殊意义（用于命令替换），因此在前面加上了反斜杠进行转义。这样可以告诉 Bash 这是一个普通字符，而不是特殊字符
    line="${line//\`/}"

    #删除*
    line="${line//\*/}"

    #如果只想替换字符串中的第一个匹配项，可以使用单个斜杠 /
    #删除"#### "
    line="${line/\#\#\#\# /}"

    #删除"### "
    line="${line/\#\#\# /}"

    #删除"## "
    line="${line/\#\# /}"

    #将处理后的行写入临时文件
    echo "$line" >>"$temp_file"
done <"$input"

if [[ "${source}" -eq 0 ]]; then
    #将临时文件替换为原文件
    mv "$temp_file" "$input"
else
    cat "$temp_file"
fi
