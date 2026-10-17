#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[tmux] Debian/Ubuntu (apt-get) is required." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends tmux
rm -rf /var/lib/apt/lists/*

mkdir -p "/usr/local/share/devcontainer-features/tmux"
install -m 0755 "${0%/*}/setup-persistence.sh" "/usr/local/share/devcontainer-features/tmux/setup-persistence.sh"
