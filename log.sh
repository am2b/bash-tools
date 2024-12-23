#!/usr/bin/env bash

#=log
#@日志系统
#@usage:
#@1:source BASH_TOOLS_LOG_SH
#@2:enable log:call enable_log "$0"(default log dir:/tmp/log/bash-tools/)
#@3.a:log_debug messages
#@3.b:log_info messages
#@3.c:log_warn messages
#@3.d:log_error messages
#@4:disable log:
#@4.a:comment out the call to the function:enable_log
#@or:
#@4.b:comment out the:source log.sh

#copy the following code to the beginning of your script.sh(snippet;log)
#if ! source $BASH_TOOLS_LOG_SH 2>/dev/null; then
#    LOG_FUNCTIONS=("enable_log" "change_default_log_level" "log_debug" "log_info" "log_warn" "log_error")
#    for func in "${LOG_FUNCTIONS[@]}"; do
#        declare -f "${func}" >/dev/null || eval "${func}() { :; }"
#    done
#else
#    enable_log "$0"
#fi

#日志开关
LOG_ENABLED=false

#日志级别的优先级
declare -A LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
#默认日志级别
DEFAULT_LOG_LEVEL=INFO
LOG_FILE=""

_log() {
    local level="${1}"
    local msg="${2}"

    if $LOG_ENABLED; then
        local timestamp=$(date "+%Y-%m-%d_%H:%M:%S")
        #检查当前日志级别是否需要记录
        if [[ ${LEVELS[$level]} -ge ${LEVELS[$DEFAULT_LOG_LEVEL]} ]]; then
            echo "[$timestamp] [$level] $msg" >>"${LOG_FILE}"
        fi
    fi
}

enable_log() {
    if (($# != 1)); then
        exit 1
    fi

    local log_base_name=$(basename "$1")
    local log_file_name="${log_base_name/%.*/}".log

    if [[ ! -d "${BASH_TOOLS_LOG_DIR}" ]]; then
        mkdir -p "${BASH_TOOLS_LOG_DIR}"
    fi

    LOG_ENABLED=true

    LOG_FILE="${BASH_TOOLS_LOG_DIR}"/"${log_file_name}"
    if [[ -s "${LOG_FILE}" ]]; then
        echo >>"${LOG_FILE}"
    fi
}

change_default_log_level() {
    if [[ -v LEVELS[$1] ]]; then
        DEFAULT_LOG_LEVEL="${1}"
    fi
}

log_debug() {
    local msg="${1}"
    _log DEBUG "${msg}"
}

log_info() {
    local msg="${1}"
    _log INFO "${msg}"
}

log_warn() {
    local msg="${1}"
    _log WARN "${msg}"
}

log_error() {
    local msg="${1}"
    _log ERROR "${msg}"
}
