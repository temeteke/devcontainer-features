#!/usr/bin/env bash
set -euo pipefail

SOURCE="/mnt/devcontainer-features/tmux/tmux.conf"
: "${HOME:?HOME must be set}"
TARGET="$HOME/.tmux.conf"

if [[ ! -f "$SOURCE" ]]; then
  echo "[tmux] Host ~/.tmux.conf mount is missing or is not a file: $SOURCE" >&2
  exit 1
fi

if [[ -L "$TARGET" ]]; then
  if [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    exit 0
  fi
  echo "[tmux] Refusing to replace existing symlink: $TARGET" >&2
  exit 1
elif [[ -e "$TARGET" ]]; then
  echo "[tmux] Refusing to overwrite existing container file: $TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
echo "[tmux] Linked $TARGET -> $SOURCE"
