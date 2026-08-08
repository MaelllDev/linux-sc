#!/usr/bin/env bash
#
# atualizar-sistema.sh
# Atualiza todos os pacotes do sistema usando o gerenciador de pacotes
# detectado (apt, dnf, yum, pacman, zypper ou apk).
# Requer privilégios de root (usa sudo quando necessário).
#
# Uso:
#   ./atualizar-sistema.sh
#   sudo ./atualizar-sistema.sh
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

# ---------- sudo ----------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        warn "Não está rodando como root e 'sudo' não foi encontrado. A atualização pode falhar."
    fi
fi

# ---------- detecta o gerenciador de pacotes ----------
PKG_MANAGER=""
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
elif command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
else
    err "Nenhum gerenciador de pacotes conhecido foi encontrado."
    err "Sistema não suportado ou gerenciador fora do PATH."
    exit 1
fi

log "Gerenciador detectado: ${PKG_MANAGER}"

# ---------- atualiza ----------
atualizar() {
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get update -y || { err "Falha no 'apt-get update'."; return 1; }
            $SUDO apt-get upgrade -y || { err "Falha no 'apt-get upgrade'."; return 1; }
            ;;
        dnf)
            $SUDO dnf upgrade -y || { err "Falha no 'dnf upgrade'."; return 1; }
            ;;
        yum)
            $SUDO yum update -y || { err "Falha no 'yum update'."; return 1; }
            ;;
        pacman)
            $SUDO pacman -Syu --noconfirm || { err "Falha no 'pacman -Syu'."; return 1; }
            ;;
        zypper)
            $SUDO zypper --non-interactive update || { err "Falha no 'zypper update'."; return 1; }
            ;;
        apk)
            $SUDO apk update || { err "Falha no 'apk update'."; return 1; }
            $SUDO apk upgrade || { err "Falha no 'apk upgrade'."; return 1; }
            ;;
    esac
}

if atualizar; then
    ok "Sistema atualizado com sucesso."
else
    err "A atualização do sistema falhou."
    exit 1
fi
