#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="opencode"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
FEATURE_ENV="${FEATURE_DIR}/feature.env"
if [ -f "${FEATURE_ENV}" ]; then
  # shellcheck disable=SC1090
  . "${FEATURE_ENV}"
fi

PERSIST="${PERSIST:-true}"
CACHE="${CACHE:-true}"
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

nearest_existing() {
  local path="$1"
  while [ ! -e "$path" ] && [ "$path" != "/" ]; do
    path="$(dirname "$path")"
  done
  printf '%s\n' "$path"
}

mount_of() {
  local path
  local mnt

  path="$(nearest_existing "$1")"

  if command -v findmnt >/dev/null 2>&1; then
    mnt="$(findmnt -n -o TARGET -T "$path" 2>/dev/null | head -n1 || true)"
    if [ -n "$mnt" ]; then
      printf '%s\n' "$mnt"
      return 0
    fi
  fi

  if command -v stat >/dev/null 2>&1; then
    mnt="$(stat -c '%m' "$path" 2>/dev/null || true)"
    if [ -n "$mnt" ]; then
      printf '%s\n' "$mnt"
      return 0
    fi
  fi
}

link_dir() {
  local src="$1"
  local dst="$2"
  local backup
  local mnt
  local src_mnt

  src_mnt="$(mount_of "$src")"
  if [ -z "$src_mnt" ] || [ "$src_mnt" = "/" ]; then
    log "Warning: $src is not on a mounted host path. Leaving $dst untouched."
    return 0
  fi

  ensure_writable_dir "$src"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst" || true)"
    if [ "$current" = "$src" ]; then
      log "Already linked: $dst -> $src"
      return 0
    fi
  fi

  mnt="$(mount_of "$dst")"
  if [ -z "$mnt" ]; then
    log "Warning: Cannot determine the mount for $dst. Leaving it untouched."
    return 0
  fi
  if [ "$mnt" != "/" ]; then
    log "Warning: $dst is on mount $mnt. Leaving it untouched."
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -d "$dst" ] && rmdir "$dst" 2>/dev/null; then
      log "Removed empty directory: $dst"
    else
      backup="${dst}.devcontainer-backup"
      if [ -e "$backup" ] || [ -L "$backup" ]; then
        local index=1
        while [ -e "${backup}.${index}" ] || [ -L "${backup}.${index}" ]; do
          index=$((index + 1))
        done
        backup="${backup}.${index}"
      fi
      if mv "$dst" "$backup"; then
        log "Moved existing $dst to $backup"
      else
        log "Error: Failed to move $dst. Persistence was not configured."
        return 1
      fi
    fi
  fi

  if ln -sfn "$src" "$dst"; then
    log "Linked: $dst -> $src"
  else
    log "Error: Failed to create symlink $dst -> $src. Persistence was not configured."
    return 1
  fi
}

ensure_writable_dir "$BASE_DIR"

if is_true "$PERSIST"; then
  link_dir "$BASE_DIR/config" "$HOME/.config/opencode"
  link_dir "$BASE_DIR/data" "$HOME/.local/share/opencode"
else
  log "Persistence disabled."
fi

if is_true "$CACHE"; then
  link_dir "$BASE_DIR/cache" "$HOME/.cache/opencode/npm" || log "Warning: failed to link the plugin cache."
else
  log "Plugin cache sharing disabled."
fi

if [ -x "${FEATURE_DIR}/warmup.sh" ]; then
  "${FEATURE_DIR}/warmup.sh" || true
fi
