#!/usr/bin/env bash
#
# backup-dir.sh
# Cria um backup compactado (tar.gz) de um diretório em ~/backups, com
# data/hora no nome e rotação automática (mantém os últimos N backups).
#
# Uso:
#   ./backup-dir.sh /caminho/do/diretorio [quantos_manter]
#   Exemplo: ./backup-dir.sh ~/Documentos 5
#
# Dica: defina BACKUP_DIR para trocar o destino (padrão: ~/backups).
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

# ---------- argumentos ----------
DIR="${1:-}"
KEEP="${2:-7}"

if [ -z "$DIR" ]; then
    err "Informe o diretório a ser copiado."
    err "Uso: ./backup-dir.sh /caminho/do/diretorio [quantos_manter]"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    err "Diretório não encontrado: $DIR"
    exit 1
fi

case "$KEEP" in
    ''|*[!0-9]*) KEEP=7 ;;
esac
if [ "$KEEP" -lt 1 ]; then
    KEEP=1
fi

# ---------- backup ----------
DEST="${BACKUP_DIR:-${HOME:-}/backups}"
mkdir -p "$DEST"

NOME="$(basename "$DIR")"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARQUIVO="${DEST}/${NOME}-${TIMESTAMP}.tar.gz"

log "Compactando '$DIR'..."
tar -czf "$ARQUIVO" -C "$(dirname "$DIR")" "$(basename "$DIR")"
ok "Backup criado: $ARQUIVO"
ok "Tamanho: $(du -h "$ARQUIVO" 2>/dev/null | awk '{print $1}')"

# ---------- rotação: mantém apenas os KEEP mais recentes ----------
contador=0
while IFS= read -r f; do
    contador=$((contador + 1))
    if [ "$contador" -gt "$KEEP" ]; then
        rm -f "$f"
        warn "Backup antigo removido: $(basename "$f")"
    fi
done < <(ls -1t "$DEST"/"${NOME}"-*.tar.gz 2>/dev/null)

ok "Feito. Backups em: $DEST (mantendo os últimos $KEEP)"
