#!/usr/bin/env bash
#
# apply-input.sh — instala o p1defaults de um sistema específico no config do FBNeo.
#
# Uso:
#   ./apply-input.sh capcom     # instala layout Capcom (CPS 6-botões)
#   ./apply-input.sh snk        # instala layout SNK/Neo Geo (4-botões)
#
#   SRC=/outro/p1defaults.ini ./apply-input.sh   # arquivo customizado
#   FBNEO_CFG_DIR=/caminho/config ./apply-input.sh capcom
#
# Nota: o fbneo-launch.sh faz esse deploy automaticamente ao escolher o sistema.
# Use este script apenas para forçar um layout sem abrir um jogo.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FBNEO_CFG_DIR="${FBNEO_CFG_DIR:-$HOME/.local/share/fbneo/config}"

declare -A SYS_CONFIG=(
  [capcom]="$SCRIPT_DIR/input_configs/p1defaults-capcom.ini"
  [snk]="$SCRIPT_DIR/input_configs/p1defaults-snk.ini"
)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

sys="${1:-}"

if [[ -n "${SRC:-}" ]]; then
  src="$SRC"
elif [[ -n "$sys" && -n "${SYS_CONFIG[$sys]+x}" ]]; then
  src="${SYS_CONFIG[$sys]}"
else
  die "Uso: $0 capcom|snk   (ou SRC=/caminho/p1defaults.ini $0)"
fi

TARGET="$FBNEO_CFG_DIR/p1defaults.ini"

[[ -f "$src" ]] || die "fonte não encontrada: $src"
mkdir -p "$FBNEO_CFG_DIR"

if [[ -f "$TARGET" ]]; then
  backup="${TARGET}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -- "$TARGET" "$backup"
  log "Backup: $backup"
fi

cp -- "$src" "$TARGET"
log "Aplicado [$sys]: $TARGET"
warn "Jogos com config/games/<rom>.ini próprio precedem este default."
warn "Para herdar o novo layout: rm $FBNEO_CFG_DIR/games/*.ini"
