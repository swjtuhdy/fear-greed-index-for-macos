#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT_DIR/dist/fear-greed-index-for-macos.app"
BUILD_SCRIPT="$ROOT_DIR/build-app.sh"

echo "==> Building app for local run"
"$BUILD_SCRIPT"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Run stopped: app bundle not found at $APP_PATH"
  exit 1
fi

echo "==> Launching app"
/usr/bin/open "$APP_PATH"
