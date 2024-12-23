#!/usr/bin/env bash

#=password
#@usage:script.sh "otpauth_url"

# 输入 otpauth URL
otpauth_url="$1"

# 使用 sed 提取 secret 和 issuer
secret=$(echo "$otpauth_url" | sed -n 's|.*secret=\([^&]*\).*|\1|p')
issuer=$(echo "$otpauth_url" | sed -n 's|.*issuer=\([^&]*\).*|\1|p')

# 提取 account
account=$(echo "$otpauth_url" | sed -n 's|.*totp/\([^?]*\)?.*|\1|p')

# 根据 issuer 判断是否需要 URL 解码
if [[ "$issuer" == "Google" ]]; then
    account=$(echo "$account" | sed 's/%3A/:/' | sed 's/%40/@/')
fi

# 判断是否需要移除 issuer 前缀
if [[ "$account" == "$issuer:"* ]]; then
    account=${account#"$issuer:"}
fi

# 输出结果
echo "account=$account"
echo "secret=$secret"
echo "issuer=$issuer"
