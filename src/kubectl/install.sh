#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="kubectl"
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

curl_retry() {
  curl -fsSL --retry 3 --connect-timeout 10 "$@"
}

validate_version() {
  local value="$1"
  case "$value" in
    ""|*[!0-9A-Za-z._-]*)
      echo "[${FEATURE_ID}] Invalid version: $value"
      exit 1
      ;;
  esac
}

if ! is_true "${INSTALL:-true}"; then
  echo "[${FEATURE_ID}] Installation disabled."
  exit 0
fi

KUBECTL_VERSION="${VERSION:-latest}"
KUBECTL_VERSION="${KUBECTL_VERSION#v}"

if [ "$KUBECTL_VERSION" = "latest" ]; then
  STABLE_RELEASE="$(curl_retry "https://dl.k8s.io/release/stable.txt")"
  KUBECTL_VERSION="${STABLE_RELEASE#v}"
fi

validate_version "$KUBECTL_VERSION"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) KUBECTL_ARCH="amd64" ;;
  aarch64|arm64) KUBECTL_ARCH="arm64" ;;
  *) echo "[${FEATURE_ID}] Unsupported architecture: $ARCH" && exit 1 ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DOWNLOAD_URL="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"
CHECKSUM_URL="${DOWNLOAD_URL}.sha256"

echo "[${FEATURE_ID}] Downloading ${DOWNLOAD_URL}"
curl_retry -o "$TMP_DIR/kubectl" "$DOWNLOAD_URL"
EXPECTED_SHA="$(curl_retry "$CHECKSUM_URL" | awk '{ print $1 }' | head -n1)"

case "$EXPECTED_SHA" in
  ""|*[!0-9a-f]*)
    echo "[${FEATURE_ID}] Failed to parse the kubectl checksum."
    exit 1
    ;;
esac
if [ "${#EXPECTED_SHA}" -ne 64 ]; then
  echo "[${FEATURE_ID}] Unexpected kubectl checksum length."
  exit 1
fi

echo "[${FEATURE_ID}] Verifying sha256 for kubectl ${KUBECTL_VERSION}"
echo "${EXPECTED_SHA}  ${TMP_DIR}/kubectl" | sha256sum -c -

install -m 0755 "$TMP_DIR/kubectl" /usr/local/bin/kubectl

echo "[${FEATURE_ID}] kubectl ${KUBECTL_VERSION} installed successfully."
