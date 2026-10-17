#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${VIM_FEATURE_CONFIG_FILE:-/mnt/devcontainer-features/vim/vimrc}"
CONFIG_DIR="${VIM_FEATURE_CONFIG_DIR:-/mnt/devcontainer-features/vim/vim}"
: "${HOME:?HOME must be set}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[vim] Host ~/.vimrc mount is missing or is not a file: $CONFIG_FILE" >&2
  exit 1
fi
if [[ ! -d "$CONFIG_DIR" ]]; then
  echo "[vim] Host ~/.vim mount is missing or is not a directory: $CONFIG_DIR" >&2
  exit 1
fi

link_config() {
  local source="$1" target="$2" kind="$3"

  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      return 0
    fi
    echo "[vim] Refusing to replace existing symlink: $target" >&2
    return 1
  fi

  if [[ "$kind" == dir && -d "$target" ]]; then
    if [[ -n "$(ls -A "$target")" ]]; then
      echo "[vim] Refusing to replace nonempty directory: $target" >&2
      return 1
    fi
    rmdir "$target"
  elif [[ -e "$target" ]]; then
    echo "[vim] Refusing to overwrite existing container path: $target" >&2
    return 1
  fi

  ln -s "$source" "$target"
  echo "[vim] Linked $target -> $source"
}

# Check both destinations before modifying either to avoid partial migration.
for dest in "$HOME/.vimrc" "$HOME/.vim"; do
  case "$dest" in
    "$HOME/.vimrc") src="$CONFIG_FILE"; kind=file ;;
    "$HOME/.vim") src="$CONFIG_DIR"; kind=dir ;;
  esac
  if [[ -L "$dest" && "$(readlink "$dest")" != "$src" ]] ||
     [[ ! -L "$dest" && -e "$dest" &&
       ( "$kind" == file || ! -d "$dest" || -n "$(ls -A "$dest")" ) ]]; then
    echo "[vim] Refusing to replace pre-existing container configuration: $dest" >&2
    exit 1
  fi
done

link_config "$CONFIG_FILE" "$HOME/.vimrc" file
link_config "$CONFIG_DIR" "$HOME/.vim" dir
