#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="opencode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR" "${BASE_DIR}/cache"
cp "${SCRIPT_DIR}/setup-persistence.sh" "$FEATURE_DIR/"
cp "${SCRIPT_DIR}/warmup.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh" "$FEATURE_DIR/warmup.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
PERSIST="${PERSIST:-true}"
CACHE="${CACHE:-true}"
WARMUP="${WARMUP:-true}"
ENVEOF

# The cache volume is initialized from this directory. Make sure the container
# user can write to it when Docker creates the volume for the first time.
cache_user="${_REMOTE_USER:-${_CONTAINER_USER:-}}"
if [ -n "$cache_user" ] && [ "$cache_user" != "automatic" ] && [ "$cache_user" != "auto" ] && id -u "$cache_user" >/dev/null 2>&1; then
  chown "$cache_user" "${BASE_DIR}/cache" || chmod 0777 "${BASE_DIR}/cache"
else
  chmod 0777 "${BASE_DIR}/cache"
fi

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
  npm install -g @opencode/cli
else
  npm install -g "@opencode/cli@${VERSION}"
fi
