#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="cline"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
FEATURE_ENV="${FEATURE_DIR}/feature.env"
if [ -f "${FEATURE_ENV}" ]; then
  # shellcheck disable=SC1090
  . "${FEATURE_ENV}"
fi

PERSIST="${PERSIST:-true}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

log() {
  echo "[${FEATURE_ID}] $*"
}

is_true() {
  case "${1:-}" in
    true|True|TRUE|1|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_writable_dir() {
  local dir="$1"
  mkdir -p "$dir"
  if [ ! -w "$dir" ]; then
    log "Warning: $dir is not writable by $(id -un). Trying to continue."
  fi
}

link_dir() {
  local src="$1"
  local dst="$2"

  ensure_writable_dir "$src"
  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst" || true)"
    if [ "$current" = "$src" ]; then
      log "Already linked: $dst -> $src"
      return 0
    fi
    rm -f "$dst"
  fi

  if [ -e "$dst" ]; then
    log "Migrating existing data from $dst to $src"
    cp -a "$dst/." "$src/" 2>/dev/null || true
    rm -rf "$dst"
  fi

  ln -sfn "$src" "$dst"
  log "Linked: $dst -> $src"
}

if ! is_true "$PERSIST"; then
  log "Persistence disabled."
  exit 0
fi

ensure_writable_dir "$BASE_DIR"

link_dir "$BASE_DIR/Documents/Cline" "$HOME/Documents/Cline"
link_dir "$BASE_DIR/cline" "$HOME/.cline"
