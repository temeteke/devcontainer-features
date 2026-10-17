#!/usr/bin/env bash
set -euo pipefail

# Test overrides are only used when running the repository's smoke tests.
SOURCE="${VIM_FEATURE_CONFIG_DIR:-/mnt/devcontainer-features/vim/config}"
: "${HOME:?HOME must be set}"
TARGET="$HOME/.vim"

if [[ ! -d "$SOURCE" ]]; then
  echo "[vim] Shared config directory is missing: $SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$TARGET")"

if [[ -L "$TARGET" ]]; then
  if [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    exit 0
  fi
  echo "[vim] Refusing to replace existing symlink: $TARGET" >&2
  exit 1
elif [[ -d "$TARGET" ]]; then
  if [[ -n "$(ls -A "$TARGET")" ]]; then
    echo "[vim] Refusing to replace nonempty directory: $TARGET" >&2
    exit 1
  fi
  rmdir "$TARGET"
elif [[ -e "$TARGET" ]]; then
  echo "[vim] Refusing to replace existing file: $TARGET" >&2
  exit 1
fi

ln -s "$SOURCE" "$TARGET"
echo "[vim] Linked $TARGET -> $SOURCE (read-only bind mount)"
