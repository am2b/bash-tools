#!/usr/bin/env bash

#=python
#@通过pyenv安装python
#@usage:
#@script.sh 3.12.0
#@script.sh 12
#@script.sh 12.2

# 编译选项
export PYTHON_CONFIGURE_OPTS="
--enable-shared
--enable-optimizations 
--with-lto
"

VERSION_PREFIX="3."

RAW_VERSION="$1"

mesg="请传递正确的版本号(例如:3.11.0,11.0或11)"

if [[ -z "${RAW_VERSION}" ]]; then
    echo "${mesg}"
    exit 1
fi

if [[ $1 =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    if [[ $1 =~ ^3\.[0-9]+\.[0-9]+$ ]]; then
        # 完整版本号3.x.y,直接使用
        VERSION="$1"
    elif [[ $1 =~ ^[0-9]+\.[0-9]+$ ]]; then
        # 输入格式为x.y,补全为3.x.y
        VERSION="${VERSION_PREFIX}${1}"
    elif [[ $1 =~ ^[0-9]+$ ]]; then
        # 输入单个数字,解释为中间数字3.x.0
        VERSION="${VERSION_PREFIX}${1}.0"
    else
        echo "${mesg}"
        exit 1
    fi
else
    echo "${mesg}"
    exit 1
fi

# 检查版本是否已安装
if pyenv versions --bare | grep -q "^$VERSION\$"; then
    echo "Python $VERSION 已经安装,无需重复安装"
    exit 0
fi

# 检查版本号是否有效
# 获取pyenv支持的所有版本列表
VALID_VERSIONS=$(pyenv install --list | awk '{gsub(/^[ \t]+/, ""); if ($1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/) print $1}')

if ! echo "$VALID_VERSIONS" | grep -q "^${VERSION}$"; then
    echo "错误:版本号 ${VERSION} 不存在"
    exit 1
fi

CACHE_DIR="$HOME/.pyenv/cache/"
if [[ ! -d "${CACHE_DIR}" ]]; then
    mkdir -p "$CACHE_DIR"
fi

NAME_TAR_XZ="Python-${VERSION}.tar.xz"
PATH_TAR_XZ="${CACHE_DIR}${NAME_TAR_XZ}"

#查看本地是否有安装包
if [[ ! -e ${PATH_TAR_XZ} ]]; then
    #下载Python源码包
    DOWNLOAD_URL="https://repo.huaweicloud.com/python/${VERSION}/${NAME_TAR_XZ}"
    echo "开始下载Python ${VERSION} ..."
    echo '----------------------------------------'
    wget "$DOWNLOAD_URL" -P "$CACHE_DIR"
    echo '----------------------------------------'
    #这里如果下载失败的话,pyenv install就会在真正安装的时候从https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tgz下载
fi

# 安装Python
echo "开始安装Python ${VERSION}"
echo "编译时间略长,请耐心等待..."
echo '----------------------------------------'
if ! pyenv install "$VERSION"; then
    echo "安装失败,请检查pyenv环境是否正确配置!"
    exit 1
fi

# 安装完成提示
echo '----------------------------------------'
echo "Python $VERSION 安装完成!"
echo
echo "可能需要重启shell"
echo
# 提供切换版本的命令
echo "可以使用以下命令切换Python版本:"
echo "设置全局版本:pyenv global $VERSION"
echo "设置本地版本:pyenv local $VERSION"
