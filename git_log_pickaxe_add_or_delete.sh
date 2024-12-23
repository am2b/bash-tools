#!/usr/bin/env bash

#=git-log
#@给定一个字符串,找到该字符串被添加或者删除的全部提交
#@usage:
#@script.sh "some_string"

script=$(basename "$0")
arrow="--->"
usage_default="to find commits that added or removed the given 'string'"

# Usage function
usage() {
    echo "Usage:"
    echo "$script 'string' $arrow $usage_default"
    exit 1
}

# 检查参数数量
if [[ $# -ne 1 ]]; then
    usage
fi

# 获取要查找的字符串
to_find="$1"

# 构造并执行命令
cmd="git log --oneline --decorate --patch --graph --all -S \"$to_find\""
eval "$cmd"

#-S <string>:
#Git的-S选项(Pickaxe)用于查找与某个字符串添加或删除相关的提交
#例如,如果某个字符串在某次提交中被添加或者被删除,git log -S会列出相关的提交
#git log -S并不是基于提交记录的描述,而是基于代码内容的实际变更

#需要注意的限制:
#如果某个字符串只是被修改(例如从foo改为foobar),但没有完全新增或删除,-S可能不会检测到,这种情况下可以使用-G选项
#-S和-G的区别:
#-S <string>:
#检查某个字符串是否新增或删除
#示例:
#如果foo在某次提交中被添加或移除,-S "foo" 会找到该提交
#-G <pattern>:
#检查某个字符串或正则表达式是否改动
#示例:
#如果foo被修改为foobar,或者仅仅调整了它所在的上下文,-G "foo" 仍然会找到该提交。

#总结:
#-S适合查找新增或删除的提交
#-G更强大,适合查找字符串的任何变动

#如果需要确保找到字符串的新增,删除,或者修改的任何提交,可以使用-G选项,例如:
#git log -G "some_string" --oneline --decorate --patch --graph --all
#这将查找包含字符串some_string的所有相关变更,无论是新增,删除,还是修改

#-G与-L的区别:
#如果你知道要查找的模式或字符串,但不关心具体文件或函数上下文:
#使用-G
#它适合快速找到某个字符串/正则在所有提交中的增删情况

#如果你知道特定的文件和行号或函数名,并希望跟踪其演化历史:
#使用git log -L
#它可以追踪该代码块的变迁,即使代码被移动或重构

#结合使用-G与-L:
#可以先用-G搜索提交历史中是否存在某些模式的改动
#如果确定改动存在,并想深入分析具体文件中的某行或函数的变化历史,再使用-L进行追踪
