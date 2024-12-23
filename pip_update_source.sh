#!/usr/bin/env bash

#=python
#@update pip source

# 备份 pip 的配置文件
PIP_CONFIG_FILE="$HOME/.config/pip/pip.conf"
BACKUP_FILE="$HOME/.config/pip/pip.conf.bak"

# 检查 pip 配置文件是否存在，如果不存在则自动生成一个
if [[ ! -f "${PIP_CONFIG_FILE}" ]]; then
    echo "[global]" >"${PIP_CONFIG_FILE}"
    echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >>"${PIP_CONFIG_FILE}"
    echo "extra-index-url = https://pypi.org/simple" >>"${PIP_CONFIG_FILE}"
    echo "已创建 pip 配置文件并设置默认源"
fi

# 备份配置文件
cp "${PIP_CONFIG_FILE}" "${BACKUP_FILE}"
echo "已备份 pip 配置文件到: ${BACKUP_FILE}"
echo

# 对官方源和国内的 pip 镜像源进行测速
echo "正在测速..."
echo

# 定义源及其中文名
declare -A SOURCES=(
    ["官方源"]="https://pypi.org/simple"
    ["清华源"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["中科大"]="https://pypi.mirrors.ustc.edu.cn/simple"
    ["阿里云"]="https://mirrors.aliyun.com/pypi/simple"
    ["豆瓣"]="https://pypi.douban.com/simple"
)

# 测速函数
function test_speed() {
    URL=$1
    # 使用 curl 测试下载时间
    TIME=$(curl -o /dev/null -s -w "%{time_total}\n" $URL)
    echo "$URL $TIME"
}

# 测试各个源的速度
declare -A SPEEDS
#!SOURCES 代表获取数组 SOURCES 的所有键
#[@] 表示获取数组中的所有元素
#整个表达式 ${!SOURCES[@]} 会展开为数组 SOURCES 中所有的键，形成一个以空格分隔的列表
#这段代码的作用是遍历 SOURCES 关联数组中的所有键，将每个键依次赋值给变量 NAME，然后可以在循环体中使用 NAME 来访问对应的值
#比如：
#echo "${SOURCES[$NAME]}"
#这将打印与当前键对应的值
for NAME in "${!SOURCES[@]}"; do
    URL=${SOURCES[$NAME]}
    SPEED=$(test_speed "${URL}")
    SPEEDS["$NAME"]="$SPEED"
done

#这个数组是为了排序而把每个时间从关联数组里面给提取出来
#每个元素由两部分组成，前一部分是时间，后一部分是源的名字，二者之间用空格分开
speeds=()
for NAME in "${!SPEEDS[@]}"; do
    TIME=$(echo "${SPEEDS[$NAME]}" | awk '{print $2}') # 提取测速结果中的时间
    speeds+=("$TIME $NAME")                            # 将时间和源名称存入 speeds 数组
done

# 按速度排序
#sorted数组就是排序后的
#每个元素由两部分组成，前一部分是时间，后一部分是源的名字，二者之间用空格分开
IFS=$'\n' sorted=($(sort -n <<<"${speeds[*]}"))
unset IFS

#打印排序
for e in "${sorted[@]}"; do
    time=$(echo "${e}" | awk '{print $1}')
    name=$(echo "${e}" | awk '{print $2}')
    echo "${name}":"${time}"
done
echo

# 标记每个源是否已被使用
declare -A SETTING_STATUS
for NAME in "${!SOURCES[@]}"; do
    SETTING_STATUS[$NAME]=false
done

# 设置 index-url
#sorted:每个元素由两部分组成，前一部分是时间，后一部分是源的名字，二者之间用空格分开
fastest_name=$(echo "${sorted[0]}" | awk '{print $2}')
index_url=${SOURCES[$fastest_name]}
SETTING_STATUS[$fastest_name]=true # 将已使用的源标记为 true

# 根据条件设置 extra-index-url
extra_urls=() # 存储 extra-index-url

# 如果 index-url 不是清华源，则将清华源设置为第一个 extra-index-url
if [[ "${SETTING_STATUS["清华源"]}" == false ]]; then
    extra_urls+=("${SOURCES["清华源"]}")
    SETTING_STATUS["清华源"]=true

    # 检查官方源的设置状态
    if [[ "${SETTING_STATUS["官方源"]}" == false ]]; then
        extra_urls+=("${SOURCES["官方源"]}")
        SETTING_STATUS["官方源"]=true # 将官方源标记为 true
    fi
else
    # 如果 index-url 是清华源，则将官方源设置为第一个 extra-index-url
    extra_urls+=("${SOURCES["官方源"]}")
    SETTING_STATUS["官方源"]=true
fi

# 至此最多只设置了2个extra-index-url,总共设置3个
# 从剩余源中找出速度最快的源以补足 extra-index-url
still_need_extral_index_url_count=$((3 - ${#extra_urls[@]}))

#从sorted数组中取出其标记是false的元素
#注意:元素是源的名字,该数组里面没有存时间,因为没有必要,顺序本身就代表了速度的快慢
sorted_still_false=()
for e in "${sorted[@]}"; do
    name=$(echo "${e}" | awk '{print $2}')
    status=${SETTING_STATUS["${name}"]}
    if [[ "${status}" == false ]]; then
        SETTING_STATUS["${name}"]=true
        sorted_still_false+=("${name}")
    fi
done

# 将 index-url 写入配置文件
echo "[global]" >"${PIP_CONFIG_FILE}"
echo "index-url = ${index_url}" >>"${PIP_CONFIG_FILE}"
echo "已将速度最快的源 ${fastest_name} 设置为了 index_url"

# 将 extra-index-url 写入配置文件
echo "extra-index-url = " >>"${PIP_CONFIG_FILE}"
for url in "${extra_urls[@]}"; do
    echo "    ${url}" >>"${PIP_CONFIG_FILE}"
done

#still_need_extral_index_url_count有可能是1或者2
#那么seq 0 $(("${still_need_extral_index_url_count}" - 1))将会产生序列0或者序列0 1
for i in $(seq 0 $(("${still_need_extral_index_url_count}" - 1))); do
    name=${sorted_still_false[$i]}
    url=${SOURCES[$name]}
    echo "    ${url}" >>"${PIP_CONFIG_FILE}"
done

# 打印出当前的 pip 配置文件
echo
echo "当前 pip 配置文件内容:"
cat "${PIP_CONFIG_FILE}"
