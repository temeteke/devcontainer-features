#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="agents"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
cp "${0%/*}/setup-persistence.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
PERSIST="${PERSIST:-true}"
ENVEOF

echo "[${FEATURE_ID}] Shared agents directory feature installed."
