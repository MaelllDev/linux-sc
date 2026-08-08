#!/usr/bin/env bash
#
# gerar-hashes.sh
# Regenera automaticamente o bloco OPCOES_SHA256 (verificação de integridade)
# do painel.sh, calculando o sha256 de cada script referenciado nas URLs.
#
# O hash é calculado do blob STAGED (git show :<arquivo>) — ou seja, do
# conteúdo exato que será commitado — com fallback para o arquivo local.
# Isso garante que o hash registrado no painel sempre corresponda ao que o
# GitHub serve (raw.githubusercontent.com).
#
# Uso:
#   ./gerar-hashes.sh           # atualiza os hashes no painel.sh
#   ./gerar-hashes.sh --hook    # instala um pre-commit hook (automático a cada commit)
#
set -euo pipefail

# ---------- configuração ----------
PAINEL="painel.sh"
GERADOR="gerar-hashes.sh"
MARK_START="# >>> gerado automaticamente por ${GERADOR} (não edite à mão) >>>"
MARK_END="# <<< fim do bloco gerado <<<"

# ---------- cores ----------
C_OK="\033[1;32m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"
C_RESET="\033[0m"

ok()   { echo -e "${C_OK}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_WARN}[!]${C_RESET} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_RESET} $*"; }

# ---------- sha256 ----------
hash_stream() {
    # hash_stream < stdin > stdout  — hash do conteúdo recebido via stdin
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        err "Nenhuma ferramenta de sha256 (sha256sum/shasum) encontrada."
        exit 1
    fi
}

normalizar_eol() {
    # remove CR apenas no fim de linha (portável: GNU e BSD sed)
    sed "s/$(printf '\r')$//"
}

# ---------- lê os itens de um array do painel.sh ----------
ler_itens() {
    local var="$1"
    awk -v v="$var" '
        index($0, v "=(") > 0 { dentro = 1; next }
        dentro && $0 ~ /^\)/ { dentro = 0; next }
        dentro && $0 ~ /^[[:space:]]*"/ {
            sub(/^[[:space:]]*"/, ""); sub(/"[[:space:]]*$/, "");
            print
        }
    ' "$PAINEL"
}

# ---------- regenera o bloco OPCOES_SHA256 ----------
regenerar() {
    if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
        err "Nenhuma ferramenta de sha256 (sha256sum/shasum) encontrada."
        exit 1
    fi

    if [ ! -f "$PAINEL" ]; then
        err "'$PAINEL' não encontrado. Rode este script na raiz do repositório."
        exit 1
    fi

    if ! grep -qF "$MARK_START" "$PAINEL"; then
        err "Marcador não encontrado no '$PAINEL':"
        err "  $MARK_START"
        err "Adicione o bloco OPCOES_SHA256 com os marcadores antes de rodar o gerador."
        exit 1
    fi

    mapfile -t nomes < <(ler_itens OPCOES_NOME)
    mapfile -t urls < <(ler_itens OPCOES_URL)

    if [ "${#urls[@]}" -eq 0 ]; then
        err "Nenhuma URL encontrada em OPCOES_URL. Confira o '$PAINEL'."
        exit 1
    fi

    if [ "${#urls[@]}" -ne "${#nomes[@]}" ]; then
        warn "OPCOES_URL (${#urls[@]} itens) e OPCOES_NOME (${#nomes[@]} itens) têm tamanhos diferentes."
        warn "Confira o painel.sh — o menu pode quebrar."
    fi

    temp_bloco="$(mktemp)"
    temp_painel="$(mktemp)"
    trap 'rm -f "$temp_bloco" "$temp_painel"' EXIT

    # ATENÇÃO: os avisos (warn) devem ir para o STDOUT do script, nunca para o
    # temp_bloco — senão poluem o bloco OPCOES_SHA256 gerado no painel.sh.
    echo "OPCOES_SHA256=(" > "$temp_bloco"
    for url in "${urls[@]}"; do
        arquivo="$(basename "$url")"

        if git cat-file -e ":$arquivo" >/dev/null 2>&1; then
            # bytes exatos do blob staged = o que será commitado e servido pelo GitHub
            hash="$(git show ":$arquivo" | hash_stream)"
            if [ -f "$arquivo" ] && ! git diff --quiet -- "$arquivo"; then
                warn "'$arquivo' tem alterações não staged; o hash registrado é da versão staged."
            fi
        elif [ -f "$arquivo" ]; then
            # ainda não rastreado: usa o arquivo local (o gitattributes normalizará p/ LF no add)
            hash="$(normalizar_eol < "$arquivo" | hash_stream)"
            warn "'$arquivo' ainda não foi adicionado ao git; hash calculado do arquivo local."
        else
            warn "Arquivo '$arquivo' (referenciado em OPCOES_URL) não encontrado."
            printf '    ""   # %s (não encontrado)\n' "$arquivo" >> "$temp_bloco"
            continue
        fi

        printf '    "%s"   # %s\n' "$hash" "$arquivo" >> "$temp_bloco"
    done
    echo ")" >> "$temp_bloco"

    awk -v ini="$MARK_START" -v fim="$MARK_END" -v bloco="$temp_bloco" '
        index($0, ini) > 0 {
            print
            while ((getline linha < bloco) > 0) print linha
            close(bloco)
            pulando = 1
            next
        }
        pulando && index($0, fim) > 0 { print; pulando = 0; next }
        pulando { next }
        { print }
    ' "$PAINEL" > "$temp_painel"
    mv "$temp_painel" "$PAINEL"

    ok "painel.sh atualizado (${#urls[@]} hash(es) regenerado(s))."
    ok "Inclua o painel.sh no commit: git add painel.sh"
}

# ---------- instala o pre-commit hook ----------
instalar_hook() {
    if [ ! -d .git ]; then
        err "Diretório '.git' não encontrado. O hook deve ser instalado dentro do clone do repositório."
        return 1
    fi

    local hook=".git/hooks/pre-commit"
    mkdir -p "$(dirname "$hook")"

    cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
# Regenera automaticamente os hashes do painel.sh a cada commit.
# Instalado por: ./gerar-hashes.sh --hook
if [ -f gerar-hashes.sh ]; then
    before="$(sha256sum painel.sh 2>/dev/null | awk '{print $1}')"
    saida="$(bash gerar-hashes.sh 2>&1)"
    if [ $? -ne 0 ]; then
        echo "gerar-hashes.sh falhou — commit abortado (hashes podem estar desatualizados)." >&2
        printf '%s\n' "$saida" >&2
        exit 1
    fi
    # repassa apenas avisos/erros do gerador (suprime as mensagens [OK])
    printf '%s\n' "$saida" | grep -E '\[!\]|\[ERRO\]' >&2 || true
    after="$(sha256sum painel.sh 2>/dev/null | awk '{print $1}')"
    if [ -n "$before" ] && [ "$before" != "$after" ]; then
        git add painel.sh
    fi
fi
HOOK
    chmod +x "$hook"
    ok "Pre-commit hook instalado em '$hook'."
    ok "Agora, a cada 'git commit', os hashes são regenerados automaticamente."
}

# ---------- main ----------
case "${1:-}" in
    --hook)
        instalar_hook
        ;;
    -h|--help)
        echo "Uso: ./gerar-hashes.sh [opção]"
        echo ""
        echo "Opções:"
        echo "  (sem opção)   Regenera os hashes SHA-256 no painel.sh"
        echo "  --hook        Instala o pre-commit hook (regeneração automática)"
        echo "  -h, --help    Mostra esta ajuda"
        ;;
    "")
        regenerar
        ;;
    *)
        err "Argumento desconhecido: $1"
        echo "Use './gerar-hashes.sh --help' para ver as opções."
        exit 1
        ;;
esac
