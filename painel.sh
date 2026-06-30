#!/usr/bin/env bash
#
# painel.sh
# Painel inicial com menu de opções. Cada opção baixa e executa um script
# hospedado no GitHub (raw.githubusercontent.com).
#
# Uso:
#   chmod +x painel.sh
#   ./painel.sh
#
set -uo pipefail

# ---------- cores ----------
C_TITLE="\033[1;36m"
C_OPT="\033[1;37m"
C_NUM="\033[1;32m"
C_INFO="\033[1;34m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"
C_RESET="\033[0m"

log()  { echo -e "${C_INFO}[*]${C_RESET} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RESET} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_RESET} $*"; }

# =========================================================================
# CONFIGURAÇÃO DAS OPÇÕES DO MENU
# Adicione novas opções aqui: nome (texto exibido) + URL do script "raw".
# Basta seguir o mesmo padrão das linhas abaixo.
# =========================================================================
OPCOES_NOME=(
    "Instalar neofetch/fastfetch (mostra system info ao abrir terminal)"
    # "Outro script aqui"
    # "Mais um script aqui"
)

OPCOES_URL=(
    "https://raw.githubusercontent.com/MaelllDev/linux-sc/refs/heads/main/install-fetch.sh"
    # "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/refs/heads/main/outro-script.sh"
    # "https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/refs/heads/main/mais-um.sh"
)
# =========================================================================

# ---------- escolhe o downloader disponível ----------
DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    err "Nem 'curl' nem 'wget' foram encontrados. Instale um dos dois para continuar."
    exit 1
fi

baixar_para() {
    # baixar_para <url> <destino>
    local url="$1"
    local destino="$2"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url" -o "$destino"
    else
        wget -q "$url" -O "$destino"
    fi
}

executar_script() {
    local url="$1"
    local nome="$2"

    log "Baixando script: ${nome}..."

    local tmpfile
    tmpfile="$(mktemp /tmp/painel-script.XXXXXX.sh)"

    if ! baixar_para "$url" "$tmpfile"; then
        err "Falha ao baixar o script de: $url"
        rm -f "$tmpfile"
        return 1
    fi

    chmod +x "$tmpfile"

    log "Executando..."
    echo ""

    # Executa em um sub-shell bash, passando bash explicitamente
    # pra não depender do shebang/permissão do arquivo baixado.
    bash "$tmpfile"
    local status=$?

    rm -f "$tmpfile"

    echo ""
    if [ $status -eq 0 ]; then
        log "Script '${nome}' finalizado com sucesso."
    else
        warn "Script '${nome}' terminou com código de saída ${status}."
    fi

    return $status
}

mostrar_menu() {
    clear
    echo -e "${C_TITLE}=============================================${C_RESET}"
    echo -e "${C_TITLE}              PAINEL DE SCRIPTS              ${C_RESET}"
    echo -e "${C_TITLE}=============================================${C_RESET}"
    echo ""

    local i
    for i in "${!OPCOES_NOME[@]}"; do
        printf " ${C_NUM}%2d)${C_RESET} ${C_OPT}%s${C_RESET}\n" "$((i + 1))" "${OPCOES_NOME[$i]}"
    done

    echo ""
    echo -e " ${C_NUM} 0)${C_RESET} Sair"
    echo ""
}

# ---------- loop principal ----------
while true; do
    mostrar_menu

    read -rp "Escolha uma opção: " escolha

    if [ "$escolha" = "0" ]; then
        echo "Até mais!"
        break
    fi

    # valida se é número
    if ! [[ "$escolha" =~ ^[0-9]+$ ]]; then
        warn "Opção inválida. Digite um número."
        sleep 1.5
        continue
    fi

    indice=$((escolha - 1))

    if [ "$indice" -lt 0 ] || [ "$indice" -ge "${#OPCOES_NOME[@]}" ]; then
        warn "Opção inválida."
        sleep 1.5
        continue
    fi

    executar_script "${OPCOES_URL[$indice]}" "${OPCOES_NOME[$indice]}"

    echo ""
    read -rp "Pressione ENTER para voltar ao menu..." _
done
