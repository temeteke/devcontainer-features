#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="opencode"
FEATURE_DIR="/usr/local/share/devcontainer-features/${FEATURE_ID}"
FEATURE_ENV="${FEATURE_DIR}/feature.env"
if [ -f "${FEATURE_ENV}" ]; then
  # shellcheck disable=SC1090
  . "${FEATURE_ENV}"
fi

WARMUP="${WARMUP:-true}"
TIMEOUT_SECONDS="${OPENCODE_WARMUP_TIMEOUT:-120}"
case "$TIMEOUT_SECONDS" in
  ''|*[!0-9]*) TIMEOUT_SECONDS=120 ;;
esac

log() {
  echo "[${FEATURE_ID}] $*"
}

is_true() {
  case "${1:-}" in
    true|True|TRUE|1|yes|YES|y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

probe_service() {
  opencode api get /api/provider >/dev/null 2>&1
}

if ! is_true "$WARMUP"; then
  log "Warm-up disabled."
  exit 0
fi

if ! command -v opencode >/dev/null 2>&1; then
  log "OpenCode is not installed. Skipping warm-up."
  exit 0
fi

if probe_service; then
  log "OpenCode service is already ready."
  exit 0
fi

log "Waiting for OpenCode service and plugins (up to ${TIMEOUT_SECONDS}s)."
deadline=$((SECONDS + TIMEOUT_SECONDS))
while [ "$SECONDS" -lt "$deadline" ]; do
  if probe_service; then
    log "OpenCode service is ready."
    exit 0
  fi
  sleep 1
done

log "Warning: OpenCode service did not become ready within ${TIMEOUT_SECONDS}s. Continuing."
exit 0
