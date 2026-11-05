#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="helmfile"
SYSTEM_PLUGIN_DIR="/usr/local/share/helm/plugins/diff"

log() {
  echo "[${FEATURE_ID}] $*"
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

if [ ! -d "$SYSTEM_PLUGIN_DIR" ]; then
  log "Warning: helm-diff was not installed at $SYSTEM_PLUGIN_DIR. Skipping."
  exit 0
fi

if [ ! -f "$SYSTEM_PLUGIN_DIR/plugin.yaml" ] || [ ! -x "$SYSTEM_PLUGIN_DIR/bin/diff" ]; then
  log "Warning: helm-diff at $SYSTEM_PLUGIN_DIR is incomplete. Skipping."
  exit 0
fi

PLUGIN_DIR=""
if command -v helm >/dev/null 2>&1; then
  PLUGIN_DIR="$(helm env HELM_PLUGINS 2>/dev/null | head -n1 || true)"
fi
PLUGIN_DIR="${PLUGIN_DIR:-${HELM_PLUGINS:-${HELM_DATA_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/helm}/plugins}}"

case "$PLUGIN_DIR" in
  /*) ;;
  *) PLUGIN_DIR="$HOME/$PLUGIN_DIR" ;;
esac

mnt="$(mount_of "$PLUGIN_DIR")"
if [ -z "$mnt" ]; then
  log "Warning: Cannot determine the mount for $PLUGIN_DIR. Leaving it untouched."
  exit 0
fi
if [ "$mnt" != "/" ]; then
  log "Warning: $PLUGIN_DIR is on mount $mnt. Leaving it untouched."
  exit 0
fi

if ! mkdir -p "$PLUGIN_DIR"; then
  log "Error: Failed to create $PLUGIN_DIR."
  exit 1
fi

if [ -L "$PLUGIN_DIR/diff" ]; then
  current="$(readlink "$PLUGIN_DIR/diff" || true)"
  if [ "$current" = "$SYSTEM_PLUGIN_DIR" ]; then
    log "Already linked: $PLUGIN_DIR/diff -> $SYSTEM_PLUGIN_DIR"
    exit 0
  fi
  if [ -e "$PLUGIN_DIR/diff" ]; then
    log "Warning: $PLUGIN_DIR/diff already points to $current. Leaving it untouched."
    exit 0
  fi
  log "Removing broken symlink: $PLUGIN_DIR/diff"
  rm -f "$PLUGIN_DIR/diff"
fi

if [ -e "$PLUGIN_DIR/diff" ]; then
  if [ -f "$PLUGIN_DIR/diff/plugin.yaml" ] && [ -x "$PLUGIN_DIR/diff/bin/diff" ]; then
    log "Existing valid helm-diff plugin found at $PLUGIN_DIR/diff. Leaving it untouched."
  else
    log "Warning: Existing $PLUGIN_DIR/diff is not a valid helm-diff plugin. Leaving it untouched."
  fi
  exit 0
fi

if ln -sfn "$SYSTEM_PLUGIN_DIR" "$PLUGIN_DIR/diff"; then
  log "Linked: $PLUGIN_DIR/diff -> $SYSTEM_PLUGIN_DIR"
else
  log "Error: Failed to create symlink $PLUGIN_DIR/diff -> $SYSTEM_PLUGIN_DIR."
  exit 1
fi
