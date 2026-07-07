#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Chord"
VERSION="${VERSION:?VERSION is required}"
DIST_DIR="$ROOT/dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/chord-${VERSION}.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: missing app bundle at $APP_PATH (run ./scripts/build.sh first)" >&2
  exit 1
fi

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "error: create-dmg is not installed (brew install create-dmg)" >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

create-dmg \
  --volname "Chord" \
  --window-pos 200 120 \
  --window-size 600 300 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 120 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 425 120 \
  --skip-jenkins \
  "$DMG_PATH" \
  "$STAGING_DIR"

rm -rf "$STAGING_DIR"

echo "Created $DMG_PATH"
