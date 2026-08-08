#!/usr/bin/env bash
#
# install-fetch.sh
# Instala o neofetch (ou, se não estiver disponível, o fastfetch) em
# praticamente qualquer distro Linux (Ubuntu, Debian, Fedora, Arch,
# openSUSE, Alpine, etc) e configura o shell para limpar a tela e
# mostrar o fetch toda vez que um terminal/sessão for aberto.
#
# Uso:
#   chmod +x install-fetch.sh
#   ./install-fetch.sh          # instala para o usuário atual (recomendado)
#   sudo ./install-fetch.sh     # se precisar de privilégios pra instalar pacotes
#                               # (o shell configurado é o do usuário que chamou o sudo)
#
set -euo pipefail

# ---------- cores pra deixar bonito ----------
C_OK="\033[1;32m"
C_INFO="\033[1;34m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"
C_RESET="\033[0m"

log()  { echo -e "${C_INFO}[*]${C_RESET} $*"; }
ok()   { echo -e "${C_OK}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RESET} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_RESET} $*"; }

# ---------- precisa de root pra instalar pacotes ----------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        warn "Não estou rodando como root e o 'sudo' não foi encontrado."
        warn "A instalação dos pacotes pode falhar."
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
    PKG_MANAGER="none"
fi

log "Gerenciador de pacotes detectado: ${PKG_MANAGER}"

# ---------- funções de instalação ----------
install_pkg() {
    local pkg="$1"
    case "$PKG_MANAGER" in
        apt)
            $SUDO apt-get update -y
            $SUDO apt-get install -y "$pkg"
            ;;
        dnf)
            $SUDO dnf install -y "$pkg"
            ;;
        yum)
            $SUDO yum install -y "$pkg"
            ;;
        pacman)
            $SUDO pacman -Sy --noconfirm "$pkg"
            ;;
        zypper)
            $SUDO zypper --non-interactive install "$pkg"
            ;;
        apk)
            $SUDO apk add --no-cache "$pkg"
            ;;
        *)
            return 1
            ;;
    esac
}

# ---------- 1) tenta instalar o neofetch pelo repositório oficial ----------
FETCH_BIN=""

if command -v neofetch >/dev/null 2>&1; then
    ok "neofetch já está instalado."
    FETCH_BIN="neofetch"
else
    log "Tentando instalar o neofetch pelo gerenciador de pacotes..."
    if install_pkg neofetch 2>/dev/null && command -v neofetch >/dev/null 2>&1; then
        ok "neofetch instalado com sucesso."
        FETCH_BIN="neofetch"
    else
        warn "Não foi possível instalar o neofetch pelo repositório (pacote pode não existir mais, ex: Fedora/Arch removeram dos repos oficiais)."
    fi
fi

# ---------- 2) se não conseguiu, parte pro fastfetch ----------
if [ -z "$FETCH_BIN" ]; then
    if command -v fastfetch >/dev/null 2>&1; then
        ok "fastfetch já está instalado."
        FETCH_BIN="fastfetch"
    else
        log "Tentando instalar o fastfetch pelo gerenciador de pacotes..."
        if install_pkg fastfetch 2>/dev/null && command -v fastfetch >/dev/null 2>&1; then
            ok "fastfetch instalado com sucesso via pacote."
            FETCH_BIN="fastfetch"
        fi
    fi
fi

# ---------- 3) último recurso: baixar o .deb/.rpm/binário do fastfetch no GitHub ----------
if [ -z "$FETCH_BIN" ]; then
    warn "fastfetch não disponível no repositório. Tentando baixar release oficial do GitHub..."

    ARCH="$(uname -m)"
    case "$ARCH" in
        x86_64) FF_ARCH="amd64" ;;
        aarch64|arm64) FF_ARCH="aarch64" ;;
        *) FF_ARCH="" ;;
    esac

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    if [ -n "$FF_ARCH" ] && command -v curl >/dev/null 2>&1; then
        API_URL="https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest"
        log "Consultando última release do fastfetch..."

        if [ "$PKG_MANAGER" = "apt" ]; then
            ASSET_PATTERN="linux-${FF_ARCH}.deb"
        elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "zypper" ]; then
            ASSET_PATTERN="linux-${FF_ARCH}.rpm"
        else
            ASSET_PATTERN="linux-${FF_ARCH}.tar.gz"
        fi

        DOWNLOAD_URL="$(curl -fsSL "$API_URL" 2>/dev/null \
            | grep "browser_download_url" \
            | grep "$ASSET_PATTERN" \
            | head -n1 \
            | cut -d '"' -f4 || true)"

        if [ -n "${DOWNLOAD_URL:-}" ]; then
            log "Baixando: $DOWNLOAD_URL"
            FILE="$TMPDIR/$(basename "$DOWNLOAD_URL")"
            curl -fsSL "$DOWNLOAD_URL" -o "$FILE"

            case "$FILE" in
                *.deb)
                    $SUDO dpkg -i "$FILE" || $SUDO apt-get install -f -y
                    ;;
                *.rpm)
                    $SUDO rpm -i "$FILE" 2>/dev/null || $SUDO dnf install -y "$FILE" 2>/dev/null || $SUDO zypper --non-interactive install "$FILE"
                    ;;
                *.tar.gz)
                    tar -xzf "$FILE" -C "$TMPDIR"
                    BIN_PATH="$(find "$TMPDIR" -type f -name fastfetch | head -n1)"
                    if [ -n "$BIN_PATH" ]; then
                        $SUDO install -m 755 "$BIN_PATH" /usr/local/bin/fastfetch
                    fi
                    ;;
            esac

            if command -v fastfetch >/dev/null 2>&1; then
                ok "fastfetch instalado manualmente com sucesso."
                FETCH_BIN="fastfetch"
            fi
        else
            err "Não foi possível encontrar um release compatível com sua arquitetura ($ARCH)."
        fi
    else
        err "curl não disponível ou arquitetura não suportada para download direto."
    fi
fi

# ---------- resultado final ----------
if [ -z "$FETCH_BIN" ]; then
    err "Não foi possível instalar neofetch nem fastfetch. Instale manualmente."
    exit 1
fi

ok "Programa escolhido: ${FETCH_BIN}"

# ---------- configura o shell para limpar a tela e rodar o fetch ----------
MARKER_START="# >>> auto-fetch (neofetch/fastfetch) >>>"
MARKER_END="# <<< auto-fetch (neofetch/fastfetch) <<<"

SNIPPET="$MARKER_START
if [ -t 1 ] && command -v ${FETCH_BIN} >/dev/null 2>&1; then
    clear
    ${FETCH_BIN}
fi
$MARKER_END"

add_snippet_to_file() {
    local file="$1"

    # cria o arquivo se não existir
    [ -f "$file" ] || touch "$file"

    # remove bloco antigo (se existir) pra evitar duplicar em re-execuções
    if grep -qF "$MARKER_START" "$file" 2>/dev/null; then
        sed -i "/$(printf '%s' "$MARKER_START" | sed 's/[.[\*^$/]/\\&/g')/,/$(printf '%s' "$MARKER_END" | sed 's/[.[\*^$/]/\\&/g')/d" "$file"
    fi

    {
        echo ""
        echo "$SNIPPET"
    } >> "$file"

    ok "Configurado em: $file"
}

# adiciona no .bashrc e .zshrc do usuário (se existirem ou puderem ser criados)
# Quando o script roda via 'sudo', o HOME aponta para /root. Detecta o
# usuário real (SUDO_USER) para configurar o shell correto do dono.
REAL_USER="${SUDO_USER:-}"
HOME_RESOLVED=0

if [ -n "$REAL_USER" ]; then
    # home do usuário real pelo banco de usuários (getent); senão, via ~
    USER_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
    if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
        USER_HOME="$(eval echo "~${REAL_USER}" || true)"
    fi
    if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
        warn "Não foi possível determinar o home de '$REAL_USER'; usando ${HOME:-/root}."
        USER_HOME="${HOME:-/root}"
    else
        HOME_RESOLVED=1
    fi
else
    USER_HOME="${HOME:-/root}"
fi

add_snippet_to_file "${USER_HOME}/.bashrc"

if [ -f "${USER_HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
    add_snippet_to_file "${USER_HOME}/.zshrc"
fi

# quando via sudo, devolve a posse dos arquivos de config ao usuário real
# (só quando o home dele foi resolvido de fato; evita chown de /root no fallback)
if [ -n "$REAL_USER" ] && [ "$HOME_RESOLVED" = "1" ]; then
    chown "$REAL_USER" "${USER_HOME}/.bashrc" 2>/dev/null || true
    if [ -f "${USER_HOME}/.zshrc" ]; then
        chown "$REAL_USER" "${USER_HOME}/.zshrc" 2>/dev/null || true
    fi
fi

ok "Tudo pronto! Abra um novo terminal (ou rode 'source ~/.bashrc') para ver o ${FETCH_BIN} em ação."
