#!/usr/bin/env bash
#
# instalar-docker.sh
# Instala o Docker Engine usando o gerenciador de pacotes detectado,
# habilita o serviço e adiciona o usuário atual ao grupo 'docker'.
# Como último recurso, oferece (com confirmação) rodar o script oficial
# de instalação do Docker (get.docker.com).
#
# Requer privilégios de root (usa sudo quando necessário).
#
# Uso:
#   ./instalar-docker.sh
#   sudo ./instalar-docker.sh
#
set -uo pipefail

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

confirmar() {
    local resp
    read -rp "$1 [s/N] " resp
    [ "$resp" = "s" ] || [ "$resp" = "S" ]
}

# ---------- sudo ----------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        err "Não está rodando como root e 'sudo' não foi encontrado."
        exit 1
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
fi

log "Gerenciador detectado: ${PKG_MANAGER:-nenhum}"

# ---------- instala pelo gerenciador ----------
instalar_via_pacote() {
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get update -y || return 1
            $SUDO apt-get install -y docker.io || return 1
            ;;
        dnf|yum)
            $SUDO "$PKG_MANAGER" install -y docker || return 1
            ;;
        pacman)
            $SUDO pacman -Sy --noconfirm docker || return 1
            ;;
        zypper)
            $SUDO zypper --non-interactive install docker || return 1
            ;;
        apk)
            $SUDO apk add --no-cache docker || return 1
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

if ! instalar_via_pacote; then
    warn "Não foi possível instalar o Docker pelo gerenciador de pacotes."
    if command -v curl >/dev/null 2>&1 && confirmar "Deseja usar o script oficial do Docker (get.docker.com)?"; then
        log "Baixando e executando o script oficial (pode demorar)..."
        if ! curl -fsSL https://get.docker.com | $SUDO sh; then
            err "Falha na instalação via script oficial."
            exit 1
        fi
    else
        err "Instalação abortada. Instale o Docker manualmente."
        exit 1
    fi
fi

# ---------- habilita o serviço ----------
if [ "$PKG_MANAGER" = "apk" ] && command -v rc-update >/dev/null 2>&1; then
    $SUDO rc-update add docker default 2>/dev/null || true
    $SUDO rc-service docker start 2>/dev/null || true
elif command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable --now docker 2>/dev/null || $SUDO systemctl start docker 2>/dev/null || true
elif command -v service >/dev/null 2>&1; then
    $SUDO service docker start 2>/dev/null || true
fi

# ---------- adiciona o usuário ao grupo docker ----------
USER_ALVO="${SUDO_USER:-$(whoami)}"
if id "$USER_ALVO" >/dev/null 2>&1; then
    $SUDO usermod -aG docker "$USER_ALVO" 2>/dev/null || true
    warn "Usuário '$USER_ALVO' adicionado ao grupo 'docker'."
    warn "Reinicie a sessão (logout/login) para usar o docker sem sudo."
fi

# ---------- confirmação final ----------
if command -v docker >/dev/null 2>&1; then
    ok "Docker instalado: $(docker --version 2>/dev/null || echo 'versão desconhecida')"
else
    warn "O comando 'docker' não foi encontrado no PATH. Verifique a instalação."
fi
