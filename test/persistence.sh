#!/usr/bin/env bash
set -euo pipefail

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT

for feature in tmux vim; do
  src="$root/shared-$feature"
  home="$root/home-$feature"
  mkdir -p "$src" "$home"
  if [[ "$feature" == "tmux" ]]; then
    var="TMUX_FEATURE_CONFIG_DIR"
    target="$home/.config/tmux"
  else
    var="VIM_FEATURE_CONFIG_DIR"
    target="$home/.vim"
  fi

  script="src/$feature/setup-persistence.sh"
  env HOME="$home" "$var=$src" bash "$script"
  [[ -L "$target" && "$(readlink "$target")" == "$src" ]]
  env HOME="$home" "$var=$src" bash "$script"  # idempotent

  printf 'shared\n' > "$src/marker"
  [[ "$(cat "$target/marker")" == "shared" ]]

  # Do not replace an existing nonempty container-side config.
  conflicting_home="$root/conflict-$feature"
  conflicting_target="$conflicting_home/${target#"$home"/}"
  mkdir -p "$conflicting_target"
  printf 'keep\n' > "$conflicting_target/existing"
  if env HOME="$conflicting_home" "$var=$src" bash "$script" >/dev/null 2>&1; then
    echo "Expected conflicting $feature config to fail" >&2
    exit 1
  fi
  [[ "$(cat "$conflicting_target/existing")" == "keep" ]]
done

echo "Persistence smoke tests OK"
