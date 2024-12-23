#!/usr/bin/env bash

#=python
#@uninstall packages of pip based on package_name.unpip file

#注意:这里传递给脚本的包名字,就是之前通过pip install安装的时候所提供的包名字,也是.unpip文件名中的包名字
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
        #为了读取后面的.unpip文件考虑:
        #如果当前目录是.envrc的下级目录的话,那么进入到.envrc的目录
        if [[ "${abs_starting_dir}" != "${envrc_path}" ]]; then
            cd "${envrc_path}" || exit 1
        fi
        break
    fi
done

#如果不在虚拟环境里,则推出
if (( "${in_venv}" == 1 )); then
    echo 'please do "pip uninstall" in virtual environment'
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

#卸载之前和之后,分别导出一份全局pip的安装列表,用于diff
#下面两个变量就是全局前后导出的文件名
global_pip_before='/tmp/global_pip_before'
global_pip_after='/tmp/global_pip_after'

#package_names这个数组里面是要卸载的包的名字,但是有可能某些包已经卸载过了(提供给pip uninstall的包名字重复了),或者根本就没有安装过,所以,需要再次检查一下package_names,把已经卸载过的(或者没有安装过的)包给剔除出去
package_names_final=()
for package in "${package_names[@]}"; do
    #检查是否已经卸载过或者根本就没有安装过这个包
    unpip_file="${unpip_dir}""${package}".unpip
    if ! [ -f "${unpip_file}" ]; then
        continue
    fi
    package_names_final+=("${package}")
done

#确实需要卸载的包的数量
package_names_final_size="${#package_names_final[@]}"
#如果确实需要卸载的包的数量为0,那么就直接退出
if (( "${package_names_final_size}" == 0 )); then
    exit 0
fi

#导出全局pip list
"${global_pip}" list > "${global_pip_before}"

#至此,package_names_final里面,就是必须要卸载的包了
for package in "${package_names_final[@]}"; do
    unpip_file="${unpip_dir}""${package}".unpip
    #读取unpip_file文件
    #这里的unpip_package就是从.unpip文件中读取的每一行数据(对应一个包名字)
    while read -r unpip_package; do
        #使用虚拟环境里面的pip进行卸载
        #-y:bypass the confirmation prompt for pip uninstall
        "${venv_pip}" uninstall -y "${unpip_package}"
    done < "${unpip_file}"

    #卸载了之后,删除掉对应的.unpip文件
    rm "${unpip_file}"
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
