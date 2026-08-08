#!/usr/bin/env bash
#
# info-sistema.sh
# Exibe um relatório de informações do sistema: distribuição, kernel,
# processador, memória, uso de disco, uptime, usuário e IPs locais.
# Não requer privilégios.
#
# Uso:
#   chmod +x info-sistema.sh
#   ./info-sistema.sh
#
set -uo pipefail

# ---------- cores ----------
C_TITLE="\033[1;36m"
C_INFO="\033[1;34m"
C_OK="\033[1;32m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"
C_RESET="\033[0m"

log()  { echo -e "${C_INFO}[*]${C_RESET} $*"; }
ok()   { echo -e "${C_OK}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RESET} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_RESET} $*"; }

# ---------- detecta a distribuição ----------
detectar_distro() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        printf '%s' "${PRETTY_NAME:-${NAME:-desconhecida}}"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -ds
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    else
        uname -sr
    fi
}

# ---------- relatório ----------
echo -e "${C_TITLE}=========== RELATÓRIO DO SISTEMA ===========${C_RESET}"
printf 'Distribuição   : %s\n' "$(detectar_distro)"
printf 'Kernel         : %s\n' "$(uname -sr)"
printf 'Arquitetura    : %s\n' "$(uname -m)"

if [ -r /proc/cpuinfo ]; then
    cpu_model="$(awk -F: '/model name/ {sub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)"
    cpu_cores="$(grep -c '^processor' /proc/cpuinfo)"
    if [ -n "$cpu_model" ]; then
        printf 'Processador    : %s (%s núcleos)\n' "$cpu_model" "$cpu_cores"
    fi
fi

if [ -r /proc/meminfo ]; then
    mem_total="$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)"
    if awk '/MemAvailable/ {found=1} END {exit !found}' /proc/meminfo 2>/dev/null; then
        mem_disp="$(awk '/MemAvailable/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)"
        printf 'Memória RAM    : %s total, %s disponível\n' "$mem_total" "$mem_disp"
    else
        printf 'Memória RAM    : %s total\n' "$mem_total"
    fi
fi

if command -v uptime >/dev/null 2>&1; then
    printf 'Uptime         : %s\n' "$(uptime -p 2>/dev/null || uptime)"
fi

printf 'Usuário        : %s@%s\n' "$(whoami)" "$(hostname 2>/dev/null || echo localhost)"

ips="$(hostname -I 2>/dev/null || true)"
if [ -n "$ips" ]; then
    for ip in $ips; do
        printf 'IP local       : %s\n' "$ip"
    done
fi

if command -v df >/dev/null 2>&1; then
    echo ""
    echo "Uso dos discos:"
    df -h -x tmpfs -x devtmpfs -x overlay 2>/dev/null | sed 's/^/  /'
fi

echo ""
ok "Relatório gerado."
