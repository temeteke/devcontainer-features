#!/usr/bin/env bash
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[vim] Debian/Ubuntu (apt-get) is required." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends vim
rm -rf /var/lib/apt/lists/*

mkdir -p "/usr/local/share/devcontainer-features/vim"
install -m 0755 "${0%/*}/setup-persistence.sh" "/usr/local/share/devcontainer-features/vim/setup-persistence.sh"
