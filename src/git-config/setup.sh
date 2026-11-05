#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="git-config"
BASE_DIR="/mnt/devcontainer-features/${FEATURE_ID}"
HOST_CONFIG="${BASE_DIR}/gitconfig"
MARKER_KEY="devcontainer.gitConfig"

TMP_CONFIG=""
ENTRIES_FILE=""

log() {
  echo "[${FEATURE_ID}] $*"
}

if [ -z "${HOME:-}" ]; then
  log "Warning: HOME is not set. Skipping git config setup."
  exit 0
fi

TARGET="${HOME}/.gitconfig"
CONTAINER_CONFIG="${HOME}/.gitconfig.devcontainer"

cleanup() {
  if [ -n "${TMP_CONFIG}" ]; then
    rm -f "${TMP_CONFIG}"
  fi
  if [ -n "${ENTRIES_FILE}" ]; then
    rm -f "${ENTRIES_FILE}"
  fi
}
trap cleanup EXIT

nearest_existing() {
  local path="$1"
  while [ ! -e "$path" ] && [ "$path" != "/" ]; do
    path="$(dirname "$path")"
  done
  printf '%s\n' "$path"
}

mount_of() {
  local path
  local mnt

  path="$(nearest_existing "$1")"

  if command -v findmnt >/dev/null 2>&1; then
    mnt="$(findmnt -n -o TARGET -T "$path" 2>/dev/null | head -n1 || true)"
    if [ -n "$mnt" ]; then
      printf '%s\n' "$mnt"
      return 0
    fi
  fi

  if command -v stat >/dev/null 2>&1; then
    mnt="$(stat -c '%m' "$path" 2>/dev/null || true)"
    if [ -n "$mnt" ]; then
      printf '%s\n' "$mnt"
      return 0
    fi
  fi
}

is_excluded_key() {
  local key="$1"
  local lower="${key,,}"

  case "$lower" in
    credential.*) return 0 ;;
    http.extraheader|http.*.extraheader) return 0 ;;
    http.sslbackend|http.sslverify|http.sslkey|http.sslcert|http.sslcainfo|http.sslcookiefile|http.cookiefile|http.schannelusesslcainfo|http.sslcertpasswordprotected) return 0 ;;
    sendemail.*) return 0 ;;
    core.hookspath|core.sshcommand|core.editor|core.pager|core.askpass|core.excludesfile|core.attributesfile|core.fsmonitor|core.gitproxy|core.alternaterefscommand) return 0 ;;
    gpg.*|user.signingkey) return 0 ;;
    commit.gpgsign|tag.gpgsign|push.gpgsign) return 0 ;;
    diff.tool|diff.external|merge.tool) return 0 ;;
    diff.*.command|diff.*.textconv|merge.*.driver) return 0 ;;
    difftool.*|mergetool.*|pager.*|interactive.difffilter|sequence.editor) return 0 ;;
    filter.*|lfs.*) return 0 ;;
    web.browser|browser.*) return 0 ;;
    core.autocrlf|core.eol|core.symlinks|core.filemode|core.ignorecase|core.precomposeunicode|core.protectntfs|core.protecthfs|core.fscache|core.longpaths) return 0 ;;
    http.proxy|http.*.proxy|http.*.sslcert|http.*.sslkey|http.*.sslcainfo|http.*.sslverify|http.*.cookiefile|http.*.sslcookiefile|http.*.sslbackend|http.*.schannelusesslcainfo|http.*.sslcertpasswordprotected) return 0 ;;
    include.path|includeif.*) return 0 ;;
    core.worktree|core.repositoryformatversion|safe.directory|remote.*|submodule.*) return 0 ;;
    *) return 1 ;;
  esac
}

quote_helper_bin() {
  printf '%q' "$1"
}

append_filtered_entries() {
  local entries_file="$1"
  local entry
  local key
  local value

  while IFS= read -r -d '' entry; do
    if [ -z "$entry" ]; then
      continue
    fi

    if [[ "$entry" == *$'\n'* ]]; then
      key="${entry%%$'\n'*}"
      value="${entry#*$'\n'}"
    else
      key="$entry"
      value="true"
    fi

    if [ -z "$key" ]; then
      continue
    fi

    if is_excluded_key "$key"; then
      continue
    fi

    if [[ "${key,,}" == url.* ]]; then
      if [[ "$key" =~ ://[^/]*@ ]] || [[ "$value" =~ ^[A-Za-z][A-Za-z0-9+.-]*://[^/]*@ ]]; then
        log "Warning: skipped host git config entry with embedded credentials: $key"
        continue
      fi
    fi

    if ! git config --file "$TMP_CONFIG" --add -- "$key" "$value" 2>/dev/null; then
      log "Warning: skipped invalid host git config entry: $key"
    fi
  done < "$entries_file"
}

if ! command -v git >/dev/null 2>&1; then
  log "Error: git is not installed."
  exit 1
fi

if [ -n "${GIT_CONFIG_GLOBAL:-}" ] && [ "${GIT_CONFIG_GLOBAL}" != "$TARGET" ]; then
  log "Warning: GIT_CONFIG_GLOBAL is set to ${GIT_CONFIG_GLOBAL}. Leaving ${TARGET} untouched."
  exit 0
fi

target_mnt="$(mount_of "$TARGET")"
if [ -n "$target_mnt" ] && [ "$target_mnt" != "/" ]; then
  target_real="$(readlink -f "$TARGET" 2>/dev/null || printf '%s' "$TARGET")"
  if [ "$target_mnt" = "$TARGET" ] || [ "$target_mnt" = "$target_real" ]; then
    log "Warning: ${TARGET} is a mount point (${target_mnt}). Leaving it untouched."
    exit 0
  fi
  log "Note: ${TARGET} is on mount ${target_mnt}. Configuring it inside the container."
fi

managed=false
if [ -f "$TARGET" ] && git config --file "$TARGET" --get "$MARKER_KEY" >/dev/null 2>&1; then
  managed=true
fi

container_config_path=""
if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if [ "$managed" = false ]; then
    if [ -d "$TARGET" ] && [ ! -L "$TARGET" ]; then
      if rmdir "$TARGET" 2>/dev/null; then
        log "Removed empty directory: ${TARGET}"
      else
        log "Warning: ${TARGET} is a non-empty directory. Leaving it untouched."
        exit 0
      fi
    elif [ ! -s "$TARGET" ]; then
      rm -f "$TARGET"
      log "Removed empty file: ${TARGET}"
    elif [ -f "$HOST_CONFIG" ] && cmp -s "$TARGET" "$HOST_CONFIG"; then
      log "Existing ${TARGET} is identical to the host config. Not preserving a duplicate."
      rm -f "$TARGET"
    else
      if [ -e "$CONTAINER_CONFIG" ] || [ -L "$CONTAINER_CONFIG" ]; then
        index=1
        while [ -e "${CONTAINER_CONFIG}.${index}" ] || [ -L "${CONTAINER_CONFIG}.${index}" ]; do
          index=$((index + 1))
        done
        if mv "$CONTAINER_CONFIG" "${CONTAINER_CONFIG}.${index}"; then
          log "Moved existing ${CONTAINER_CONFIG} to ${CONTAINER_CONFIG}.${index}"
        else
          log "Warning: failed to move ${CONTAINER_CONFIG}. Skipping git config setup."
          exit 0
        fi
      fi
      if mv "$TARGET" "$CONTAINER_CONFIG"; then
        log "Moved existing ${TARGET} to ${CONTAINER_CONFIG}"
        container_config_path="$CONTAINER_CONFIG"
      else
        log "Warning: failed to move ${TARGET}. Skipping git config setup."
        exit 0
      fi
    fi
  fi
fi

if [ -z "$container_config_path" ] && { [ -f "$CONTAINER_CONFIG" ] || [ -L "$CONTAINER_CONFIG" ]; }; then
  container_config_path="$CONTAINER_CONFIG"
fi

TMP_CONFIG="$(mktemp "${TMPDIR:-/tmp}/git-config.XXXXXX")"
ENTRIES_FILE="$(mktemp "${TMPDIR:-/tmp}/git-config-entries.XXXXXX")"

if ! git config --file "$TMP_CONFIG" --add -- "$MARKER_KEY" true; then
  log "Warning: failed to initialize git config. Skipping."
  exit 0
fi

if [ -f "$HOST_CONFIG" ]; then
  if git config --file "$HOST_CONFIG" --list --includes -z > "$ENTRIES_FILE" 2>/dev/null; then
    append_filtered_entries "$ENTRIES_FILE"
    log "Inherited host git config: ${HOST_CONFIG}"
  else
    log "Warning: failed to read host git config: ${HOST_CONFIG}"
  fi
else
  log "Warning: host ~/.gitconfig is missing or is not a file: ${HOST_CONFIG}"
  log "Warning: create ~/.gitconfig on the host before opening the container."
fi

if [ -n "$container_config_path" ] && [ -s "$container_config_path" ]; then
  git config --file "$TMP_CONFIG" --add -- include.path "$container_config_path"
  log "Included container git config: ${container_config_path}"
elif [ -n "$container_config_path" ]; then
  log "Skipped empty container git config: ${container_config_path}"
fi

helpers=0

GH_BIN="$(command -v gh 2>/dev/null || true)"
if [ -n "$GH_BIN" ] && "$GH_BIN" auth git-credential --help >/dev/null 2>&1; then
  git config --file "$TMP_CONFIG" --add -- credential.helper "!$(quote_helper_bin "$GH_BIN") auth git-credential"
  log "Configured git credential helper: gh"
  helpers=$((helpers + 1))
elif [ -n "$GH_BIN" ]; then
  log "Warning: gh is installed but 'gh auth git-credential' is unavailable."
fi

GLAB_BIN="$(command -v glab 2>/dev/null || true)"
if [ -n "$GLAB_BIN" ] && "$GLAB_BIN" auth git-credential --help >/dev/null 2>&1; then
  git config --file "$TMP_CONFIG" --add -- credential.helper "!$(quote_helper_bin "$GLAB_BIN") auth git-credential"
  log "Configured git credential helper: glab"
  helpers=$((helpers + 1))
elif [ -n "$GLAB_BIN" ]; then
  log "Warning: glab is installed but 'glab auth git-credential' is unavailable."
fi

if [ "$helpers" -eq 0 ]; then
  log "Warning: neither gh nor glab is available. Install the github-cli or gitlab-cli Feature to enable git authentication."
fi

if ! mv "$TMP_CONFIG" "$TARGET"; then
  log "Warning: failed to write ${TARGET}."
  exit 0
fi
TMP_CONFIG=""
chmod 0644 "$TARGET" 2>/dev/null || log "Warning: failed to set permissions on ${TARGET}."

log "Wrote ${TARGET}."
