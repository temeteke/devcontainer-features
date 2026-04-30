#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="opencode"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
cp "${0%/*}/setup-persistence.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
INSTALL="${INSTALL:-true}"
PERSIST="${PERSIST:-true}"
VERSION="${VERSION:-latest}"
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

if [ "${VERSION:-latest}" = "latest" ]; then
  npm install -g opencode-ai
else
  npm install -g "opencode-ai@${VERSION}"
fi
