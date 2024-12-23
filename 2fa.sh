#!/usr/bin/env bash

#=password
#@generate a totp verification code

# 提示用户输入2FA密钥
echo "请输入您的Base32密钥: "
read -r SECRET_KEY

#使用 oathtool 来基于密钥和当前时间生成一个 TOTP 验证码
TOTP=$(oathtool --base32 --totp "${SECRET_KEY}")

# 输出生成的验证码
echo "您的TOTP验证码是: $TOTP"
