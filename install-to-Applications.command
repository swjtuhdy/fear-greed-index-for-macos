#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="fear-greed-index-for-macos.app"
APP_SOURCE="$ROOT_DIR/dist/$APP_NAME"
APP_TARGET="/Applications/$APP_NAME"
BUILD_SCRIPT="$ROOT_DIR/build-app.sh"

echo "==> Building $APP_NAME"
if ! "$BUILD_SCRIPT"; then
  echo
  echo "Install stopped because the app bundle could not be built."
  echo "Fix the Apple toolchain first, then run this installer again."
  exit 1
fi

if [[ ! -d "$APP_SOURCE" ]]; then
  echo "Build failed: app bundle not found at $APP_SOURCE"
  exit 1
fi

echo "==> Installing to /Applications"

if [[ -d "$APP_TARGET" ]]; then
  echo "Existing app found. It will be replaced."
fi

/usr/bin/osascript <<APPLESCRIPT
do shell script "/bin/rm -rf " & quoted form of "$APP_TARGET" & " && /bin/cp -R " & quoted form of "$APP_SOURCE" & " /Applications/ && /usr/bin/xattr -dr com.apple.quarantine " & quoted form of "$APP_TARGET" with administrator privileges
APPLESCRIPT

echo "==> Launching app"
/usr/bin/open "$APP_TARGET"

echo
echo "Installed successfully:"
echo "$APP_TARGET"
echo
echo "To launch automatically at login:"
echo "  ./enable-login-launch.command"
echo
echo "If Terminal stays open, you can close it."
