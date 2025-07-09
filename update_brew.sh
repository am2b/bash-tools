#!/usr/bin/env bash

#=tools
#@更新通过homebrew安装的包,包括Cask软件包
#@usage:
#@script.sh

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script"
    exit 1
}

process_opts() {
    while getopts ":h" opt; do
        case $opt in
        h)
            usage
            ;;
        *)
            echo "error:unsupported option -$opt"
            usage
            ;;
        esac
    done
}

check_parameters() {
    if (("$#" > 0)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    brew update

    #更新普通包
    echo "----------------------------------------"
    brew upgrade

    #更新Cask软件包
    #管道符|仅捕获stdout内容
    outdated_casks=$(brew outdated --cask --verbose | awk '{print $1}')
    if [[ -n "${outdated_casks}" ]]; then
        echo "----------------------------------------"
        for app in ${outdated_casks}; do
            brew upgrade --cask "${app}"
        done
    fi

    echo "----------------------------------------"
    brew cleanup

    #更新nvm
    echo "----------------------------------------"
    update_nvm.sh

    #更新rust
    echo "----------------------------------------"
    output=$(rustup update)
    if echo "$output" | grep -q "unchanged"; then
        echo "rust已是最新版本,无需更新"
    else
        echo "$output"
    fi

    #更新oh my zsh
    echo "----------------------------------------"
    if [ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]; then
        output=$(zsh "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>&1)

        if echo "$output" | grep -q "error"; then
            echo "${output}"
        else
            echo "Oh My Zsh has been updated"
        fi
    else
        echo "Oh My Zsh未安装或路径不正确"
    fi

    #更新tldr
    echo "----------------------------------------"
    output=$(tldr --update)
    if echo "${output}" | grep -iq "successfully"; then
        echo "tldr已更新"
    else
        echo "${output}"
    fi
}

main "${@}"
