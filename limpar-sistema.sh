#!/usr/bin/env bash
#
# limpar-sistema.sh
# Limpa caches de pacotes e remove pacotes órfãos/desnecessários usando o
# gerenciador de pacotes detectado (apt, dnf, yum, pacman, zypper ou apk).
# Requer privilégios de root (usa sudo quando necessário).
#
# Uso:
#   ./limpar-sistema.sh
#   sudo ./limpar-sistema.sh
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
        warn "Não está rodando como root e 'sudo' não foi encontrado. A limpeza pode falhar."
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

# ---------- limpa ----------
limpar() {
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get autoremove -y || return 1
            $SUDO apt-get autoclean -y || return 1
            ;;
        dnf)
            $SUDO dnf autoremove -y || return 1
            $SUDO dnf clean all || return 1
            ;;
        yum)
            $SUDO yum autoremove -y || return 1
            $SUDO yum clean all || return 1
            ;;
        pacman)
            $SUDO pacman -Sc --noconfirm || return 1
            # remove pacotes órfãos, se existirem
            orfaos="$(pacman -Qtdq 2>/dev/null || true)"
            if [ -n "$orfaos" ]; then
                # shellcheck disable=SC2086 # múltiplos pacotes de propósito
                $SUDO pacman -Rns --noconfirm $orfaos || return 1
            fi
            ;;
        zypper)
            $SUDO zypper clean -a || return 1
            ;;
        apk)
            $SUDO apk cache clean || return 1
            ;;
    esac
}

if limpar; then
    ok "Limpeza concluída."
else
    err "A limpeza do sistema falhou."
    exit 1
fi
