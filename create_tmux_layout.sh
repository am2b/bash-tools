#!/usr/bin/env bash

#=tmux
#@create layout of session
#@usage:script.sh session_name

# 检查是否提供会话名称参数
if [ -z "$1" ]; then
    echo "请提供会话名称作为第一个参数"
    exit 1
fi

# 设置会话名称
session_name=$1

# 定义窗口名称数组
window_names=("tmp" "bash" "python" "man" "config")

# 设置分屏比例
split_ratio=35
other_split_ratio=$((100 - split_ratio))

# 创建一个新的 tmux 会话，并命名为数组中的第一个窗口名称
tmux new-session -d -s "$session_name" -n "${window_names[0]}"

# 在第一个窗口左右分屏，左边占据 split_ratio 的百分比
tmux split-window -h -p "$other_split_ratio"
tmux select-pane -L # 将光标切换到左边分屏

# 循环创建并配置其他窗口
for ((i = 1; i < ${#window_names[@]}; i++)); do
    tmux new-window -t "$session_name" -n "${window_names[i]}"
    tmux split-window -h -p "$other_split_ratio"
    tmux select-pane -L # 将光标切换到左边分屏
done

# 选择第一个窗口作为启动窗口
tmux select-window -t "$session_name:${window_names[0]}"

# 附加到会话
tmux attach -t "$session_name"
