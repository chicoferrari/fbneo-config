#!/usr/bin/env bash
#
# fbneo-launch.sh — launcher do FBNeo com seletor de sistema
#
# Seleciona o sistema (Capcom / SNK), carrega o mapa de controle correto
# e exibe a lista de jogos do sistema via fzf.
#
# Uso:
#   ./fbneo-launch.sh              # picker sistema → picker jogo (fullscreen)
#   ./fbneo-launch.sh capcom       # picker jogo Capcom direto
#   ./fbneo-launch.sh snk          # picker jogo SNK direto
#   ./fbneo-launch.sh mslug        # romname direto (detecta sistema pelo dir)
#   ./fbneo-launch.sh mslug -w     # janela
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FBNEO_BIN="${FBNEO_BIN:-fbneo}"
FBNEO_CFG_DIR="${FBNEO_CFG_DIR:-$HOME/.local/share/fbneo/config}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

command -v "$FBNEO_BIN" >/dev/null || die "$FBNEO_BIN não encontrado (paru -S fbneo-git)"

# --- Definição dos sistemas ---------------------------------------------------
#   chave         dir de ROMs                               config de input
SYSTEMS=(capcom snk)

declare -A SYS_DIR=(
  [capcom]="/media/GameStorage/roms/FBNeo/capcom"
  [snk]="/media/GameStorage/roms/FBNeo/neogeo"
)
declare -A SYS_CONFIG=(
  [capcom]="$SCRIPT_DIR/input_configs/p1defaults-capcom.ini"
  [snk]="$SCRIPT_DIR/input_configs/p1defaults-snk.ini"
)
declare -A SYS_LABEL=(
  [capcom]="Capcom  (CPS-1 / CPS-2 / CPS-3)"
  [snk]="SNK     (Neo Geo)"
)

# --- Helpers ------------------------------------------------------------------

is_system() { [[ -n "${SYS_DIR[${1:-}]+x}" ]]; }

deploy_config() {
  local sys="$1"
  local src="${SYS_CONFIG[$sys]}"
  local dst="$FBNEO_CFG_DIR/p1defaults.ini"
  [[ -f "$src" ]] || die "input config não encontrada: $src"
  cp -- "$src" "$dst"
  log "Input: ${SYS_LABEL[$sys]}"
}

detect_system() {
  local romname="$1" sys
  for sys in "${SYSTEMS[@]}"; do
    [[ -f "${SYS_DIR[$sys]}/$romname.zip" ]] && { echo "$sys"; return 0; }
  done
  return 1
}

pick_system() {
  command -v fzf >/dev/null || die "fzf não encontrado"
  local sys choice
  choice="$(
    for sys in "${SYSTEMS[@]}"; do
      printf '%s\t%s\n' "$sys" "${SYS_LABEL[$sys]}"
    done \
    | fzf --prompt='Sistema > ' \
          --with-nth=2 \
          --delimiter=$'\t' \
          --height=20% \
          --reverse \
    | cut -f1
  )" || true
  [[ -n "$choice" ]] || die "nenhum sistema selecionado"
  echo "$choice"
}

pick_game() {
  local sys="$1"
  local dir="${SYS_DIR[$sys]}"
  command -v fzf >/dev/null || die "fzf não encontrado"
  [[ -d "$dir" ]] || die "dir de ROMs não encontrado: $dir"
  local game
  game="$(
    find "$dir" -maxdepth 1 -type f -iname '*.zip' -printf '%f\n' \
      | sed 's/\.[zZ][iI][pP]$//' \
      | sort -u \
      | fzf --prompt="${SYS_LABEL[$sys]} > " \
            --height=40% \
            --reverse
  )" || true
  [[ -n "$game" ]] || die "nenhum jogo selecionado"
  echo "$game"
}

# --- Main ---------------------------------------------------------------------

game="${1:-}"
shift 2>/dev/null || true
extra_args=("$@")

if [[ -z "$game" ]]; then
  # Sem argumento: picker de sistema → picker de jogo
  sys="$(pick_system)"
  deploy_config "$sys"
  game="$(pick_game "$sys")"

elif is_system "$game"; then
  # Argumento é nome de sistema: picker de jogo filtrado
  sys="$game"
  deploy_config "$sys"
  game="$(pick_game "$sys")"

else
  # Argumento é romname: detecta sistema pelo dir e faz deploy
  if sys="$(detect_system "$game")"; then
    deploy_config "$sys"
  else
    warn "Sistema não detectado para '$game' — input config não alterada"
  fi
fi

# Fullscreen por padrão; passar -w (janela) sobrescreve.
fs_flag=(-fullscreen)
for a in "${extra_args[@]}"; do
  [[ "$a" == "-w" ]] && { fs_flag=(); break; }
done
log "Rodando: $game"
exec "$FBNEO_BIN" "$game" "${fs_flag[@]}" "${extra_args[@]}"
