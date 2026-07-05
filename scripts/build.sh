#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="CASK"
DIST_DIR="$ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "Building $APP_NAME (release, universal)..."
if ! swift build -c release --arch arm64 --arch x86_64; then
  echo "Universal build failed; falling back to host architecture."
  swift build -c release
fi

BINARY=""
for candidate in \
  "$ROOT/.build/apple/Products/Release/$APP_NAME" \
  "$ROOT/.build/arm64-apple-macosx/release/$APP_NAME" \
  "$ROOT/.build/x86_64-apple-macosx/release/$APP_NAME" \
  "$ROOT/.build/release/$APP_NAME"; do
  if [[ -f "$candidate" ]]; then
    BINARY="$candidate"
    break
  fi
done

if [[ -z "$BINARY" ]]; then
  echo "error: could not find release binary for $APP_NAME" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BINARY" "$MACOS_DIR/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
chmod +x "$MACOS_DIR/$APP_NAME"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
fi

echo "Built $APP_DIR"
