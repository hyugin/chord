#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$ROOT/Resources/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "error: missing $PLIST" >&2
  exit 1
fi

CURRENT="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")"

if [[ ! "$CURRENT" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "error: unsupported version format: $CURRENT" >&2
  exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"
NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION" "$PLIST"

echo "$NEW_VERSION"
