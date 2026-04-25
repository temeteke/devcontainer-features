#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="glab"
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

GLAB_VERSION="${VERSION:-latest}"

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) GLAB_ARCH="linux_amd64" ;;
  arm64) GLAB_ARCH="linux_arm64" ;;
  *) echo "[${FEATURE_ID}] Unsupported architecture: $ARCH" && exit 1 ;;
esac

TMP_DIR="$(mktemp -d)"

if [ "$GLAB_VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://gitlab.com/gitlab-org/cli/-/releases/latest/downloads/glab_${GLAB_ARCH}.tar.gz"
else
  DOWNLOAD_URL="https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_${GLAB_ARCH}.tar.gz"
fi

curl -fsSL -o "$TMP_DIR/glab.tar.gz" "$DOWNLOAD_URL"
tar -xzf "$TMP_DIR/glab.tar.gz" -C "$TMP_DIR"
install "$(find "$TMP_DIR" -type f -name glab -print -quit)" /usr/local/bin/glab
rm -rf "$TMP_DIR"

echo "[${FEATURE_ID}] glab installed successfully."
