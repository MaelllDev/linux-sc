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
#
# IMPORTANTE: os hashes em OPCOES_SHA256 são gerados automaticamente por
# ./gerar-hashes.sh (ou pelo pre-commit hook). Depois de adicionar ou alterar
# um script, rode o gerador — nunca edite os hashes à mão.
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

# >>> gerado automaticamente por gerar-hashes.sh (não edite à mão) >>>
OPCOES_SHA256=(
[1;33m[!][0m 'install-fetch.sh' tem alterações não staged; o hash registrado é da versão staged.
    "b4e23e9d573e4c14308272e46612ff91c2b3bcad9213714bd8abf346379d38c3"   # install-fetch.sh
)
# <<< fim do bloco gerado <<<
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

confirmar() {
    # confirmar <mensagem> -> pergunta [s/N]; retorna 0 se sim
    local resp
    read -rp "$1 [s/N] " resp
    [ "$resp" = "s" ] || [ "$resp" = "S" ]
}

calcular_sha256() {
    # calcular_sha256 <arquivo> -> imprime o hash na saída padrão
    local arquivo="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$arquivo" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$arquivo" | awk '{print $1}'
    else
        return 1
    fi
}

verificar_integridade() {
    # verificar_integridade <arquivo> <hash-esperado> <nome>
    local arquivo="$1"
    local esperado="$2"
    local nome="$3"
    local real=""

    real="$(calcular_sha256 "$arquivo")" || real=""

    if [ -z "$esperado" ]; then
        warn "Nenhum checksum registrado para '$nome'."
        warn "Rode './gerar-hashes.sh' e faça commit para gerar o hash."
        if confirmar "Executar mesmo assim?"; then
            return 0
        fi
        warn "Execução cancelada pelo usuário."
        return 1
    fi

    if [ -z "$real" ]; then
        warn "Ferramenta de checksum (sha256sum/shasum) não encontrada."
        if confirmar "Não foi possível verificar a integridade. Executar mesmo assim?"; then
            return 0
        fi
        warn "Execução cancelada pelo usuário."
        return 1
    fi

    if [ "$real" = "$esperado" ]; then
        log "Integridade verificada (sha256 ok)."
        return 0
    fi

    err "ERRO DE INTEGRIDADE: o checksum de '$nome' não confere!"
    err "Esperado: $esperado"
    err "Obtido:   $real"
    err "O script pode ter sido alterado ou corrompido. Abortando execução."
    return 1
}

executar_script() {
    local url="$1"
    local nome="$2"
    local esperado="$3"

    log "Baixando script: ${nome}..."

    local tmpfile
    tmpfile="$(mktemp /tmp/painel-script.XXXXXX.sh)"

    if ! baixar_para "$url" "$tmpfile"; then
        err "Falha ao baixar o script de: $url"
        rm -f "$tmpfile"
        return 1
    fi

    if ! verificar_integridade "$tmpfile" "$esperado" "$nome"; then
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

    executar_script "${OPCOES_URL[$indice]}" "${OPCOES_NOME[$indice]}" "${OPCOES_SHA256[$indice]:-}"

    echo ""
    read -rp "Pressione ENTER para voltar ao menu..." _
done
