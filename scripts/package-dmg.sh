#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
DMG_PATH="$DIST_DIR/Backtrace.dmg"

"$SCRIPT_DIR/build-app.sh"

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
cp -R "$DIST_DIR/Backtrace.app" "$STAGING_DIR/Backtrace.app"
ln -s /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"
hdiutil create -volname "Backtrace" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

echo "$DMG_PATH"
