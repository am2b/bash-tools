#!/bin/sh

#=tools
#@portable system information script(纯POSIX sh)
#@兼容macOS,Arch,Debian,Ubuntu,Fedora,Kali,openSUSE,Rocky,Alpine
#@usage:
#@script.sh
#@script.sh --json

# -------- helpers --------
trim() { sed 's/^ *//; s/ *$//'; }

kv_from_os_release() {
    # $1 = key
    # echo value or empty
    [ -r /etc/os-release ] || {
        echo ""
        return
    }
    # shellcheck disable=SC2002
    cat /etc/os-release |
        grep -E "^$1=" |
        head -n1 |
        sed -e "s/^$1=//" -e 's/^"//; s/"$//' |
        trim
}

json_escape() {
    # Escape backslash and double-quote and control chars for simple JSON values
    # Reads stdin
    awk '
    BEGIN{ORS=""; print ""}
    {
      for(i=1;i<=length($0);i++){
        c=substr($0,i,1)
        if(c=="\\")      printf "\\\\"
        else if(c=="\"") printf "\\\""
        else if(c=="\b") printf "\\b"
        else if(c=="\f") printf "\\f"
        else if(c=="\n") printf "\\n"
        else if(c=="\r") printf "\\r"
        else if(c=="\t") printf "\\t"
        else              printf "%s", c
      }
      printf ""
    } END{print ""}
  '
}

normalize_arch() {
    case "$1" in
    x86_64 | amd64) echo "amd64" ;;
    i386 | i486 | i586 | i686) echo "386" ;;
    aarch64 | arm64) echo "arm64" ;;
    armv7l | armv7 | armhf) echo "armv7" ;;
    armv6l | armv6) echo "armv6" ;;
    ppc64le) echo "ppc64le" ;;
    s390x) echo "s390x" ;;
    riscv64) echo "riscv64" ;;
    *) echo "$1" ;;
    esac
}

detect_libc() {
    # Only meaningful on Linux
    if command -v ldd >/dev/null 2>&1; then
        v="$(ldd --version 2>&1 | head -n1)"
        case "$v" in
        *musl*) echo "$v" ;;
        *GNU*) echo "$v" ;; # glibc
        *) echo "$v" ;;
        esac
    else
        echo ""
    fi
}

# -------- collect base info --------
KERNEL_NAME="$(uname -s 2>/dev/null)"
KERNEL_RELEASE="$(uname -r 2>/dev/null)"
KERNEL_VERSION="$(uname -v 2>/dev/null)"
MACHINE="$(uname -m 2>/dev/null)"
ARCH_NORM="$(normalize_arch "$MACHINE")"

OS_NAME=""
OS_VERSION=""
OS_ID=""
OS_ID_LIKE=""
OS_CODENAME=""
LIBC_INFO=""
PKG_MANAGER=""

case "$KERNEL_NAME" in
Darwin)
    # macOS
    if command -v sw_vers >/dev/null 2>&1; then
        OS_NAME="$(sw_vers -productName 2>/dev/null)"
        OS_VERSION="$(sw_vers -productVersion 2>/dev/null)"
    else
        # Fallback (very old systems)
        OS_NAME="macOS"
        OS_VERSION=""
    fi
    OS_ID="macos"
    OS_ID_LIKE="darwin bsd"
    OS_CODENAME=""
    LIBC_INFO="Apple libc"
    PKG_MANAGER="brew (if installed)"
    ;;
Linux)
    # Prefer os-release
    if [ -r /etc/os-release ]; then
        OS_NAME="$(kv_from_os_release NAME)"
        OS_VERSION="$(kv_from_os_release VERSION)"
        OS_ID="$(kv_from_os_release ID)"
        OS_ID_LIKE="$(kv_from_os_release ID_LIKE)"
        OS_CODENAME="$(kv_from_os_release VERSION_CODENAME)"
    elif command -v lsb_release >/dev/null 2>&1; then
        OS_NAME="$(lsb_release -si 2>/dev/null)"
        OS_VERSION="$(lsb_release -sr 2>/dev/null)"
        OS_CODENAME="$(lsb_release -sc 2>/dev/null)"
        OS_ID="$(echo "$OS_NAME" | tr '[:upper:]' '[:lower:]')"
        OS_ID_LIKE=""
    else
        # Very old/minimal fallbacks
        if [ -r /etc/alpine-release ]; then
            OS_NAME="Alpine Linux"
            OS_VERSION="$(cat /etc/alpine-release)"
            OS_ID="alpine"
        elif [ -r /etc/arch-release ]; then
            OS_NAME="Arch Linux"
            OS_VERSION=""
            OS_ID="arch"
        elif [ -r /etc/debian_version ]; then
            OS_NAME="Debian"
            OS_VERSION="$(cat /etc/debian_version)"
            OS_ID="debian"
        elif [ -r /etc/redhat-release ]; then
            OS_NAME="$(cat /etc/redhat-release)"
            OS_VERSION=""
            OS_ID="rhel-like"
        else
            OS_NAME="Linux (unknown distro)"
            OS_VERSION=""
            OS_ID="linux"
        fi
        OS_ID_LIKE=""
        OS_CODENAME=""
    fi

    # libc
    LIBC_INFO="$(detect_libc)"

    # Package manager (best-effort hint)
    if command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
    else
        PKG_MANAGER=""
    fi
    ;;
*)
    # Other kernels (BSDs, etc.)
    OS_NAME="$KERNEL_NAME"
    OS_VERSION=""
    OS_ID="$(echo "$KERNEL_NAME" | tr '[:upper:]' '[:lower:]')"
    OS_ID_LIKE=""
    OS_CODENAME=""
    LIBC_INFO=""
    PKG_MANAGER=""
    ;;
esac

# -------- output --------
if [ "$1" = "--json" ]; then
    # Build JSON with basic escaping
    j() {
        printf '"%s": "%s"' "$1" "$(printf '%s' "$2" | json_escape)"
    }
    printf "{"
    j "kernel_name" "$KERNEL_NAME"
    printf ","
    j "kernel_release" "$KERNEL_RELEASE"
    printf ","
    j "kernel_version" "$KERNEL_VERSION"
    printf ","
    j "machine" "$MACHINE"
    printf ","
    j "arch_normalized" "$ARCH_NORM"
    printf ","
    j "os_name" "$OS_NAME"
    printf ","
    j "os_version" "$OS_VERSION"
    printf ","
    j "os_id" "$OS_ID"
    printf ","
    j "os_id_like" "$OS_ID_LIKE"
    printf ","
    j "os_codename" "$OS_CODENAME"
    printf ","
    j "libc" "$LIBC_INFO"
    printf ","
    j "package_manager" "$PKG_MANAGER"
    printf "}\n"
else
    cat <<EOF
Platform Information
--------------------
Kernel Name      : $KERNEL_NAME
Kernel Release   : $KERNEL_RELEASE
Kernel Version   : $KERNEL_VERSION
Machine          : $MACHINE
Arch (normalized): $ARCH_NORM

OS Name          : $OS_NAME
OS Version       : $OS_VERSION
OS ID            : $OS_ID
OS ID Like       : $OS_ID_LIKE
OS Codename      : $OS_CODENAME

libc             : $LIBC_INFO
Package Manager  : $PKG_MANAGER
EOF
fi
