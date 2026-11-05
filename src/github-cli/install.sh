#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="github-cli"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
install -m 0755 "${SCRIPT_DIR}/setup-persistence.sh" "${FEATURE_DIR}/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
PERSIST="${PERSIST:-true}"
ENVEOF

echo "[${FEATURE_ID}] GitHub CLI persistence feature installed."
