#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="pi"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR" "$BASE_DIR"
cp "${0%/*}/setup-persistence.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-persistence.sh"

cat > "${FEATURE_DIR}/feature.env" <<ENVEOF
PERSIST="${PERSIST:-true}"
ENVEOF

if [ "${INSTALL:-true}" != "true" ]; then
  echo "[${FEATURE_ID}] Installation disabled."
  exit 0
fi

package="@earendil-works/pi-coding-agent"
if [ "${VERSION:-latest}" != "latest" ]; then
  package+="@${VERSION}"
fi
npm install --global --ignore-scripts "$package"
