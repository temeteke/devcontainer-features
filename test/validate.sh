#!/usr/bin/env bash
set -euo pipefail

for f in src/*/devcontainer-feature.json; do
  echo "Validating $f"
  python3 -m json.tool "$f" >/dev/null
done

for s in src/*/*.sh; do
  echo "Syntax check $s"
  bash -n "$s"
done

echo "OK"
