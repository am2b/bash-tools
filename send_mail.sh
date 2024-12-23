#!/usr/bin/env bash

#=tools
#@usage:script.sh "subject" "body" recipient

# 检查是否安装了msmtp
if ! command -v msmtp &> /dev/null; then
    echo "msmtp未安装,正在通过Homebrew安装..."
    
    # 检查是否安装了Homebrew
    if ! command -v brew &> /dev/null; then
        echo "Homebrew未安装,请先安装Homebrew"
        exit 1
    fi
    
    # 使用Homebrew安装msmtp
    brew install msmtp
    
    # 检查是否安装成功
    if ! command -v msmtp &> /dev/null; then
        echo "msmtp安装失败,请检查Homebrew设置"
        exit 1
    else
        echo "msmtp安装成功"
    fi
fi

subject=$1
body=$2
recipient=$3

nohup sh -c "printf 'To: %s\nSubject: %s\n\n%s\n' \"$recipient\" \"$subject\" \"$body\" | msmtp \"$recipient\"" > /dev/null 2>&1 &
