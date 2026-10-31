#!/usr/bin/env bash
set -euo pipefail

validate_json() {
  local file="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -e . "$file" >/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$file" >/dev/null
  else
    echo "jq or python3 is required to validate JSON." >&2
    exit 1
  fi
}

for f in src/*/devcontainer-feature.json; do
  echo "Validating $f"
  validate_json "$f"
done

for s in src/*/*.sh; do
  echo "Syntax check $s"
  bash -n "$s"
done

echo "OK"
