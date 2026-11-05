#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="helmfile"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"

mkdir -p "$FEATURE_DIR"
cp "${SCRIPT_DIR}/setup-helm-diff.sh" "$FEATURE_DIR/"
chmod +x "$FEATURE_DIR/setup-helm-diff.sh"

is_true() {
  case "${1:-}" in
    true|True|TRUE|1|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

curl_retry() {
  curl -fsSL --retry 3 --connect-timeout 10 "$@"
}

latest_tag() {
  local repo="$1"
  local url
  url="$(curl_retry -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest")"
  printf '%s\n' "${url##*/}"
}

validate_version() {
  local name="$1"
  local value="$2"
  case "$value" in
    ""|*[!0-9A-Za-z._-]*)
      echo "[${FEATURE_ID}] Invalid ${name}: $value"
      exit 1
      ;;
  esac
}

if ! is_true "${INSTALL:-true}"; then
  echo "[${FEATURE_ID}] Installation disabled."
  exit 0
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) TOOL_ARCH="amd64" ;;
  aarch64|arm64) TOOL_ARCH="arm64" ;;
  *) echo "[${FEATURE_ID}] Unsupported architecture: $ARCH" && exit 1 ;;
esac

HELMFILE_VERSION="${VERSION:-latest}"
HELMVERSION="${HELMVERSION:-latest}"
HELMDIFFVERSION="${HELMDIFFVERSION:-latest}"

if [ "$HELMFILE_VERSION" = "latest" ]; then
  HELMFILE_VERSION="$(latest_tag "helmfile/helmfile")"
fi
HELMFILE_VERSION="${HELMFILE_VERSION#v}"

if [ "$HELMVERSION" = "latest" ]; then
  HELMVERSION="$(latest_tag "helm/helm")"
fi
HELMVERSION="${HELMVERSION#v}"

if [ "$HELMDIFFVERSION" = "latest" ]; then
  HELMDIFFVERSION="$(latest_tag "databus23/helm-diff")"
fi
HELMDIFFVERSION="${HELMDIFFVERSION#v}"

validate_version "helmfile version" "$HELMFILE_VERSION"
validate_version "Helm version" "$HELMVERSION"
validate_version "helm-diff version" "$HELMDIFFVERSION"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

HELM_ARCHIVE="helm-v${HELMVERSION}-linux-${TOOL_ARCH}.tar.gz"
HELM_URL="https://get.helm.sh/${HELM_ARCHIVE}"
echo "[${FEATURE_ID}] Downloading Helm ${HELMVERSION}"
curl_retry -o "$TMP_DIR/${HELM_ARCHIVE}" "$HELM_URL"
curl_retry -o "$TMP_DIR/${HELM_ARCHIVE}.sha256sum" "${HELM_URL}.sha256sum"
echo "[${FEATURE_ID}] Verifying sha256 for Helm ${HELMVERSION}"
(cd "$TMP_DIR" && sha256sum -c "${HELM_ARCHIVE}.sha256sum")
tar -xzf "$TMP_DIR/${HELM_ARCHIVE}" -C "$TMP_DIR" "linux-${TOOL_ARCH}/helm"
install -m 0755 "$TMP_DIR/linux-${TOOL_ARCH}/helm" /usr/local/bin/helm

HELMFILE_ARCHIVE="helmfile_${HELMFILE_VERSION}_linux_${TOOL_ARCH}.tar.gz"
HELMFILE_URL="https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/${HELMFILE_ARCHIVE}"
HELMFILE_CHECKSUMS="helmfile_${HELMFILE_VERSION}_checksums.txt"
echo "[${FEATURE_ID}] Downloading helmfile ${HELMFILE_VERSION}"
curl_retry -o "$TMP_DIR/${HELMFILE_ARCHIVE}" "$HELMFILE_URL"
curl_retry -o "$TMP_DIR/${HELMFILE_CHECKSUMS}" "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/${HELMFILE_CHECKSUMS}"
echo "[${FEATURE_ID}] Verifying sha256 for helmfile ${HELMFILE_VERSION}"
(cd "$TMP_DIR" && awk -v f="${HELMFILE_ARCHIVE}" '{ name = $2; sub(/^\*/, "", name); sub(/\r$/, "", name); if (name == f) print }' "${HELMFILE_CHECKSUMS}" | sha256sum -c -)
tar -xzf "$TMP_DIR/${HELMFILE_ARCHIVE}" -C "$TMP_DIR" helmfile
install -m 0755 "$TMP_DIR/helmfile" /usr/local/bin/helmfile

HELM_DIFF_CHECKSUMS="helm-diff_${HELMDIFFVERSION}_checksums.txt"
HELM_DIFF_ARCHIVE=""
for candidate in "diff-${HELMDIFFVERSION}-linux-${TOOL_ARCH}.tgz" "helm-diff-linux-${TOOL_ARCH}.tgz"; do
  if curl_retry -o "$TMP_DIR/${candidate}" "https://github.com/databus23/helm-diff/releases/download/v${HELMDIFFVERSION}/${candidate}" 2>/dev/null; then
    HELM_DIFF_ARCHIVE="$candidate"
    break
  fi
done

if [ -z "$HELM_DIFF_ARCHIVE" ]; then
  echo "[${FEATURE_ID}] Failed to download helm-diff ${HELMDIFFVERSION}."
  exit 1
fi

echo "[${FEATURE_ID}] Downloading helm-diff ${HELMDIFFVERSION}"
curl_retry -o "$TMP_DIR/${HELM_DIFF_CHECKSUMS}" "https://github.com/databus23/helm-diff/releases/download/v${HELMDIFFVERSION}/${HELM_DIFF_CHECKSUMS}"
echo "[${FEATURE_ID}] Verifying sha256 for helm-diff ${HELMDIFFVERSION}"
(cd "$TMP_DIR" && awk -v f="${HELM_DIFF_ARCHIVE}" '{ name = $2; sub(/^\*/, "", name); sub(/\r$/, "", name); if (name == f) print }' "${HELM_DIFF_CHECKSUMS}" | sha256sum -c -)

PLUGIN_STAGE="/usr/local/share/helm/plugins"
rm -rf "${PLUGIN_STAGE}/diff"
mkdir -p "$PLUGIN_STAGE"
tar -xzf "$TMP_DIR/${HELM_DIFF_ARCHIVE}" -C "$PLUGIN_STAGE"

if [ ! -f "${PLUGIN_STAGE}/diff/plugin.yaml" ] || [ ! -f "${PLUGIN_STAGE}/diff/bin/diff" ]; then
  echo "[${FEATURE_ID}] Invalid helm-diff archive layout."
  exit 1
fi

chown -R root:root "${PLUGIN_STAGE}/diff"
chmod -R a+rX "${PLUGIN_STAGE}/diff"
chmod 0755 "${PLUGIN_STAGE}/diff/bin/diff"

if [ ! -x "${PLUGIN_STAGE}/diff/bin/diff" ]; then
  echo "[${FEATURE_ID}] helm-diff binary is not executable."
  exit 1
fi

echo "[${FEATURE_ID}] Helm ${HELMVERSION}, helmfile ${HELMFILE_VERSION}, and helm-diff ${HELMDIFFVERSION} installed successfully."
