#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="fear-greed-index-for-macos.app"
APP_DIR="$ROOT_DIR/dist/$APP_NAME"
EXECUTABLE_PATH="$APP_DIR/Contents/MacOS/fear-greed-index-for-macos"
PLIST_PATH="$APP_DIR/Contents/Info.plist"
SOURCE_FILE="$ROOT_DIR/main.m"
ICON_TOOL_SOURCE="$ROOT_DIR/tools/generate_app_icon.m"
ICON_TOOL_BINARY="$ROOT_DIR/.build/generate_app_icon"
ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
ICON_FILE_PATH="$APP_DIR/Contents/Resources/AppIcon.icns"

function verify_clang_toolchain() {
  if ! /usr/bin/xcrun --find clang >/dev/null 2>&1; then
    echo "Apple clang was not found. Install Xcode Command Line Tools first:"
    echo "xcode-select --install"
    exit 1
  fi
}

/bin/mkdir -p "$ROOT_DIR/dist"
/bin/mkdir -p "$ROOT_DIR/.build"
rm -rf "$APP_DIR"
/bin/rm -rf "$ICONSET_DIR"
/bin/mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
verify_clang_toolchain

echo "Generating app icon..."
/usr/bin/xcrun clang \
  -fobjc-arc \
  -framework Cocoa \
  -O2 \
  "$ICON_TOOL_SOURCE" \
  -o "$ICON_TOOL_BINARY"

"$ICON_TOOL_BINARY" "$ICONSET_DIR"
/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE_PATH"

echo "Building app bundle..."
/usr/bin/xcrun clang \
  -fobjc-arc \
  -framework Cocoa \
  -O2 \
  "$SOURCE_FILE" \
  -o "$EXECUTABLE_PATH"

/bin/cp "$ROOT_DIR/Info.plist" "$PLIST_PATH"
/bin/chmod +x "$EXECUTABLE_PATH"

if /usr/bin/which codesign >/dev/null 2>&1; then
  echo "Applying ad-hoc code signature..."
  /usr/bin/codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Built: $APP_DIR"
echo "Run with:"
echo "open \"$APP_DIR\""
