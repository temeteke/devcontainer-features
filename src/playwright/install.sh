#!/usr/bin/env bash
set -euo pipefail

FEATURE_ID="playwright"

echo "[${FEATURE_ID}] Installing @playwright/cli..."
npm install -g @playwright/cli@latest

echo "[${FEATURE_ID}] Installing browser runtime and Linux dependencies..."
playwright-cli install-browser --with-deps

echo "[${FEATURE_ID}] Done."
