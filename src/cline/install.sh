#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="cline"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
cp "${0%/*}/setup-persistence.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
INSTALL="${INSTALL:-true}"
PERSIST="${PERSIST:-true}"
PERSIST_MODE="${PERSISTMODE:-${PERSIST_MODE:-all}}"
ENVEOF

is_true() {
  case "${1:-}" in
    true|True|TRUE|1|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_true "${INSTALL:-true}"; then
  echo "[${FEATURE_ID}] Installation disabled."
  exit 0
fi
echo "[cline] VS Code extension is installed by devcontainer customizations."
