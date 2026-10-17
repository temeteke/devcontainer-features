#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="dsh"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
if [ -f "${FEATURE_DIR}/feature.env" ]; then
  # shellcheck disable=SC1090
  . "${FEATURE_DIR}/feature.env"
fi

if [ "${PERSIST:-true}" != "true" ]; then
  echo "[${FEATURE_ID}] Persistence disabled."
  exit 0
fi

source_dir="/mnt/devcontainer-features/${FEATURE_ID}"
target_dir="$HOME/.dsh"

mkdir -p "$source_dir" "$(dirname "$target_dir")"
if [ ! -w "$source_dir" ]; then
  echo "[${FEATURE_ID}] Warning: $source_dir is not writable by $(id -un)." >&2
fi

if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$source_dir" ]; then
  exit 0
fi

if [ -L "$target_dir" ]; then
  rm -f "$target_dir"
elif [ -e "$target_dir" ]; then
  cp -a "$target_dir/." "$source_dir/" 2>/dev/null || true
  rm -rf "$target_dir"
fi
ln -s "$source_dir" "$target_dir"
echo "[${FEATURE_ID}] Linked $target_dir -> $source_dir"
