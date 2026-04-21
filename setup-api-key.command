#!/bin/zsh
set -euo pipefail

APP_DIR="$HOME/Library/Application Support/fear-greed-index-for-macos"
CONFIG_PATH="$APP_DIR/config.plist"

mkdir -p "$APP_DIR"

read -rs "API_KEY?Enter RapidAPI key: "
echo

if [[ -z "$API_KEY" ]]; then
  echo "No key entered."
  exit 1
fi

cat > "$CONFIG_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>rapidapi_key</key>
    <string>$API_KEY</string>
</dict>
</plist>
EOF

chmod 600 "$CONFIG_PATH"
echo "Saved key to $CONFIG_PATH"
