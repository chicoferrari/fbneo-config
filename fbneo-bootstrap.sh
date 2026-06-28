#!/usr/bin/env bash
#
# fbneo-bootstrap.sh — aponta os ROM paths do FBNeo no fbneo.ini, via upsert.
#
# O fbneo.ini e "chave valor" com comentarios em "//". O FBNeo vem com rom
# path no default (/usr/local/share/roms/); a unica coisa que precisa mudar
# e apontar pros teus dirs de romsets. Suporta multiplos dirs (Neo Geo,
# CAPCOM, ...). Audio sai por SDL2 -> PipeWire (sem o hw:0 do Mednafen).
#
# Uso:
#   ./fbneo-bootstrap.sh
#   FBNEO_CFG=/caminho/fbneo.ini ./fbneo-bootstrap.sh
#
set -euo pipefail

FBNEO_CFG="${FBNEO_CFG:-$HOME/.local/share/fbneo/config/fbneo.ini}"

# Dirs dos romsets FBNeo. O FBNeo exige barra final — o script adiciona se faltar.
declare -a ROM_PATHS=(
  "/media/GameStorage/roms/FBNeo/neogeo"
  "/media/GameStorage/roms/FBNeo/capcom"
)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# cfg_set FILE KEY VALUE — substitui "KEY ..." ou adiciona no fim (upsert)
cfg_set() {
  local file="$1" key="$2" value="$3"
  awk -v key="$key" -v value="$value" '
    BEGIN { done=0 }
    { if (!done && $1==key) { print key " " value; done=1; next } print }
    END { if (!done) print key " " value }
  ' "$file" > "$file.tmp"
}

[[ -f "$FBNEO_CFG" ]] || die "fbneo.ini nao encontrado: $FBNEO_CFG
Rode 'fbneo' uma vez pra cria-lo, ou defina FBNEO_CFG=/caminho"
command -v awk >/dev/null || die "awk nao encontrado"

backup="${FBNEO_CFG}.bak.$(date +%Y%m%d-%H%M%S)"
cp -- "$FBNEO_CFG" "$backup"
log "Backup: $backup"
log "Aplicando ROM paths (upsert)..."

for i in "${!ROM_PATHS[@]}"; do
  p="${ROM_PATHS[$i]}"
  [[ "$p" == */ ]] || p="$p/"            # FBNeo exige trailing slash
  cfg_set "$FBNEO_CFG" "szAppRomPaths[$i]" "$p"
  mv -- "$FBNEO_CFG.tmp" "$FBNEO_CFG"
  printf '    szAppRomPaths[%d] %s\n' "$i" "$p"
done

log "Pronto. Reverter: cp \"$backup\" \"$FBNEO_CFG\""
log "BIOS de arcade (neogeo.zip etc.) vao no dir do sistema correspondente."