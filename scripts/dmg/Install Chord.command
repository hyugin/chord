#!/bin/bash
# Double-click from the Chord DMG (or run in Terminal).
# Copies Chord into /Applications, clears the download quarantine flag, and launches it.
# Ad-hoc signed builds get a new code hash every release, so macOS would otherwise ask
# you to re-approve each download in System Settings → Privacy & Security.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$SOURCE_DIR/Chord.app"
DEST_APP="/Applications/Chord.app"

alert() {
  local title="$1"
  local message="$2"
  if command -v osascript >/dev/null 2>&1; then
    osascript \
      -e "on run argv" \
      -e "display alert (item 1 of argv) message (item 2 of argv) as critical" \
      -e "end run" \
      -- "$title" "$message" >/dev/null
  else
    echo "$title: $message" >&2
  fi
}

if [[ ! -d "$SOURCE_APP" ]]; then
  alert "Chord.app not found" "Keep this installer next to Chord.app inside the DMG, then try again."
  exit 1
fi

echo "Installing Chord to /Applications…"
rm -rf "$DEST_APP"
cp -R "$SOURCE_APP" "$DEST_APP"

echo "Clearing quarantine (skips Gatekeeper re-approval for this install)…"
xattr -cr "$DEST_APP"

echo "Launching Chord…"
open "$DEST_APP"

if command -v osascript >/dev/null 2>&1; then
  osascript -e 'display notification "Installed to Applications and ready to use." with title "Chord"' >/dev/null || true
fi

echo "Done."
