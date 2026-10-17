#!/usr/bin/env bash
set -euo pipefail

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

tmux_src="$root/host.tmux.conf"
vimrc_src="$root/host.vimrc"
vim_dir="$root/host.vim"
printf 'set -g mouse on\n' > "$tmux_src"
printf 'set number\n' > "$vimrc_src"
mkdir -p "$vim_dir"
printf 'sample data\n' > "$vim_dir/example.txt"

tmux_home="$root/tmux-home"
vim_home="$root/vim-home"
mkdir -p "$tmux_home" "$vim_home"

env HOME="$tmux_home" TMUX_FEATURE_CONFIG_FILE="$tmux_src" \
  bash src/tmux/setup-persistence.sh
[[ "$(readlink "$tmux_home/.tmux.conf")" == "$tmux_src" ]]
env HOME="$tmux_home" TMUX_FEATURE_CONFIG_FILE="$tmux_src" \
  bash src/tmux/setup-persistence.sh

env HOME="$vim_home" VIM_FEATURE_CONFIG_FILE="$vimrc_src" \
  VIM_FEATURE_CONFIG_DIR="$vim_dir" bash src/vim/setup-persistence.sh
[[ "$(readlink "$vim_home/.vimrc")" == "$vimrc_src" ]]
[[ "$(readlink "$vim_home/.vim")" == "$vim_dir" ]]
[[ "$(cat "$vim_home/.vim/example.txt")" == "sample data" ]]
env HOME="$vim_home" VIM_FEATURE_CONFIG_FILE="$vimrc_src" \
  VIM_FEATURE_CONFIG_DIR="$vim_dir" bash src/vim/setup-persistence.sh

# Updates inside the shared directory must be reflected at the host source.
printf 'updated\n' > "$vim_home/.vim/example.txt"
[[ "$(cat "$vim_dir/example.txt")" == "updated" ]]

# Missing source fails, and no configuration is created.
if env HOME="$root/no-tmux" TMUX_FEATURE_CONFIG_FILE="$root/missing-file" \
  bash src/tmux/setup-persistence.sh > /dev/null 2>&1; then
  echo "Missing tmux source unexpectedly accepted" >&2
  exit 1
fi
if env HOME="$root/no-vim" VIM_FEATURE_CONFIG_FILE="$vimrc_src" \
  VIM_FEATURE_CONFIG_DIR="$root/missing-dir" \
  bash src/vim/setup-persistence.sh > /dev/null 2>&1; then
  echo "Missing vim directory unexpectedly accepted" >&2
  exit 1
fi

# Conflicts preserve existing files and do not partially link.
mkdir -p "$root/conflict-tmux" "$root/conflict-vim/.vim"
printf 'keep\n' > "$root/conflict-tmux/.tmux.conf"
printf 'keep\n' > "$root/conflict-vim/.vim/existing"
if env HOME="$root/conflict-tmux" TMUX_FEATURE_CONFIG_FILE="$tmux_src" \
  bash src/tmux/setup-persistence.sh > /dev/null 2>&1; then
  echo "tmux overwrote an existing config" >&2
  exit 1
fi
if env HOME="$root/conflict-vim" VIM_FEATURE_CONFIG_FILE="$vimrc_src" \
  VIM_FEATURE_CONFIG_DIR="$vim_dir" bash src/vim/setup-persistence.sh \
  > /dev/null 2>&1; then
  echo "vim overwrote an existing config" >&2
  exit 1
fi
[[ "$(cat "$root/conflict-tmux/.tmux.conf")" == "keep" ]]
[[ "$(cat "$root/conflict-vim/.vim/existing")" == "keep" ]]
[[ ! -e "$root/conflict-vim/.vimrc" ]]

echo "Configuration link smoke tests OK"
