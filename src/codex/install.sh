#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="codex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
cp "${SCRIPT_DIR}/setup-persistence.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
PERSIST="${PERSIST:-true}"
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
  npm install -g @openai/codex
else
  npm install -g "@openai/codex@${VERSION}"
fi
