#!/usr/bin/env bash

#=python
#@make pip only execute in the virtual environment,and generate uninstall files

package_names=("${@}")

abs_starting_dir=$(realpath .)

unpip_dir='.unpip/'

#收集当前目录的祖先目录的绝对路径(包含当前目录)
#一直往上,直到遇到~,或者遇到了root
array_dirs=("${abs_starting_dir}")
parent=$(dirname "${abs_starting_dir}")
until [[ "${parent}" == $(realpath "$HOME") ]] || [[ "${parent}" == '/' ]]
do
    array_dirs+=("${parent}")
    parent=$(dirname "${parent}")
done

#在这些收集的目录array_dirs里面寻找隐藏文件.envrc
#1 is false
in_venv=1
for d in "${array_dirs[@]}"; do
    if fd --has-results --max-depth 1 --hidden --type f --glob .envrc "${d}"; then
        #0 is true
        in_venv=0
        #虚拟环境里面.envrc文件所在的绝对路径
        envrc_path="${d}"
        #为了后面生成.unpip文件考虑:
        #如果当前目录是.envrc的下级目录的话,那么进入到.envrc的目录
        if [[ "${abs_starting_dir}" != "${envrc_path}" ]]; then
            cd "${envrc_path}" || exit 1
        fi
        break
    fi
done

#如果不在虚拟环境里,则推出
if (( "${in_venv}" == 1 )); then
    echo 'please do "pip install" in virtual environment'
    exit 0
fi

#检查全局pip的路径
global_pip="${HOME}"/.pyenv/shims/pip
if ! [ -x "${global_pip}" ]; then
    echo 'path of global pip error' && exit 1
fi

#检查虚拟环境里面pip的路径
venv_pip="${envrc_path}"/.venv/bin/pip
if ! [ -x "${venv_pip}" ]; then
    echo 'path of venv pip error' && exit 1
fi

#安装之前和之后,分别导出一份全局pip的安装列表,用于diff
#下面两个变量就是全局前后导出的文件名
global_pip_before='/tmp/global_pip_before'
global_pip_after='/tmp/global_pip_after'

#package_names这个数组里面是要安装的包的名字,但是有可能某些包已经安装过了(提供给pip install的包名字重复了),所以,需要再次检查一下package_names,把已经安装过的包给剔除出去
package_names_final=()
for package in "${package_names[@]}"; do
    #检查是否已经安装过这个包了
    unpip_file="${unpip_dir}""${package}".unpip
    if [ -f "${unpip_file}" ]; then
        continue
    fi
    package_names_final+=("${package}")
done

#确实需要安装的包的数量
package_names_final_size="${#package_names_final[@]}"
#如果确实需要安装的包的数量为0,那么就直接退出
if (( "${package_names_final_size}" == 0 )); then
    exit 0
fi

#导出全局pip list
"${global_pip}" list > "${global_pip_before}"

#至此,package_names_final里面,就是必须要安装的包了
for package in "${package_names_final[@]}"; do
    #使用虚拟环境里面的pip进行安装
    #每安装一个包之前和之后,就导出一个pip list
    "${venv_pip}" list > before_"${package}".txt
    "${venv_pip}" install "${package}"
    "${venv_pip}" list > after_"${package}".txt
done

#再次导出全局pip list
"${global_pip}" list > "${global_pip_after}"

#注意:这里导出的before和after是用于检查全局的
diff_file='/tmp/diff_file.txt'
diff --unified "${global_pip_before}" "${global_pip_after}" > "${diff_file}" 
#-s:文件存在,并且非空
if [ -s "${diff_file}" ]; then
    echo '****************************************'
    cat "${diff_file}"
    echo '****************************************'
fi

#把.unpip文件放在.envrc所在目录的隐藏子目录.unpip(隐藏子目录的名字)下面
if ! [ -d "${unpip_dir}" ]; then
    mkdir "${unpip_dir}"
fi

#现在开始分析上面安装的每个包所对应的两个before和after文件,进而生成关于每次安装包的.unpip文件
for package in "${package_names_final[@]}"; do
    #.unpip文件的文件名中"${package}"就是使用pip install安装的时候,提供的包名字
    unpip_file="${unpip_dir}""${package}".unpip

    before=before_"${package}".txt
    after=after_"${package}".txt
    old=old_"${package}".txt
    new=new_"${package}".txt

    #从第3行开始,提取第一个字段(不要第2个字段的版本号)
    sed -n '3,$p' < "${before}" | awk '{print $1}' > "${old}"
    sed -n '3,$p' < "${after}" | awk '{print $1}' > "${new}"

    #观察pip list的输出是经过排序的,所以使用diff来筛选出差异行
    #丢弃掉diff输出结果的前3行,从第4行开始提取出前面有一个+的行,然后把+删除掉
    diff --unified "${old}" "${new}" | sed -n '4,$p' | sed -n '/+/p' | tr -d '+' > "${unpip_file}"

    #删除掉上面产生的4个临时txt文件
    rm "${before}" "${after}" "${old}" "${new}"
done
