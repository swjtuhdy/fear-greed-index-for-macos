#!/bin/zsh
set -euo pipefail

LABEL="com.local.fear-greed-index-for-macos"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

if [[ -f "$PLIST_PATH" ]]; then
  /bin/launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
  /bin/rm -f "$PLIST_PATH"
  echo "Login launch disabled."
else
  echo "No LaunchAgent found at $PLIST_PATH"
fi
