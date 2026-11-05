#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="git-config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
install -m 0755 "${SCRIPT_DIR}/setup.sh" "${FEATURE_DIR}/setup.sh"

if ! command -v git >/dev/null 2>&1; then
  echo "[${FEATURE_ID}] Error: git is required but was not found." >&2
  exit 1
fi

echo "[${FEATURE_ID}] Git config feature installed."
