#!/usr/bin/env bash
#
# script-exemplo.sh
# Modelo de script do linux-sc. Demonstra as convenções do projeto:
# cabeçalho de uso, cores, funções log/ok/warn/err e detecção de distro.
# Exibe informações básicas do sistema (não precisa de root).
#
# Uso:
#   chmod +x script-exemplo.sh
#   ./script-exemplo.sh
#
# Para criar um novo script a partir deste modelo:
#   1. Copie este arquivo com outro nome (ex: cp script-exemplo.sh meu-script.sh)
#   2. Adapte a descrição e o conteúdo
#   3. No painel.sh, adicione o nome em OPCOES_NOME e a URL em OPCOES_URL
#   4. Rode ./gerar-hashes.sh (ou use o pre-commit hook) para gerar o hash
#
set -euo pipefail

# ---------- cores ----------
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

# ---------- exibe informações do sistema ----------
log "Coletando informações do sistema..."
echo ""

printf 'Distribuição : %s\n' "$(detectar_distro)"
printf 'Kernel       : %s\n' "$(uname -sr)"
printf 'Arquitetura  : %s\n' "$(uname -m)"

if [ -r /proc/meminfo ]; then
    mem_total="$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo)"
    printf 'Memória RAM  : %s\n' "$mem_total"
fi

echo ""
ok "Script de exemplo concluído com sucesso."
warn "Este é apenas um modelo — copie e adapte para as suas necessidades."
