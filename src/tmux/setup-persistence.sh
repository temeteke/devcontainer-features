#!/usr/bin/env bash
set -euo pipefail

# Test overrides are only used when running the repository's smoke tests.
SOURCE="${TMUX_FEATURE_CONFIG_DIR:-/mnt/devcontainer-features/tmux/config}"
: "${HOME:?HOME must be set}"
TARGET="$HOME/.config/tmux"

if [[ ! -d "$SOURCE" ]]; then
  echo "[tmux] Shared config directory is missing: $SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

if [[ -L "$TARGET" ]]; then
  if [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    exit 0
  fi
  echo "[tmux] Refusing to replace existing symlink: $TARGET" >&2
  exit 1
elif [[ -d "$TARGET" ]]; then
  if [[ -n "$(ls -A "$TARGET")" ]]; then
    echo "[tmux] Refusing to replace nonempty directory: $TARGET" >&2
    exit 1
  fi
  rmdir "$TARGET"
elif [[ -e "$TARGET" ]]; then
  echo "[tmux] Refusing to replace existing file: $TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
echo "[tmux] Linked $TARGET -> $SOURCE (read-only bind mount)"
