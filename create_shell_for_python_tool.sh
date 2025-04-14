#!/usr/bin/env bash

#=python
#@为python命令行程序创建一个外壳bash脚本,来以便捷的方式运行python工具
#@usage:
#@script.sh python_project_name

usage() {
    local script
    script=$(basename "$0")
    echo "usage:"
    echo "$script python_project_name"
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
    if (("$#" != 1)); then
        usage
    fi
}

main() {
    check_parameters "${@}"
    process_opts "${@}"
    shift $((OPTIND - 1))

    local project_name="${1}"

    cd ~/.local/bin/python-tools || exit 1

cat << EOF > "${project_name}"
#!/usr/bin/env bash

~/repos/${project_name}/.venv/bin/cli \$@
EOF

    chmod +x "${project_name}"
}

main "${@}"
