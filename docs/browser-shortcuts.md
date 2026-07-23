# Firefox / Zen shortcut catalogue

Chord ships a **versioned macOS catalogue** of Firefox and Zen Browser shortcuts, then derives a trimmed cheat sheet from it.

## Source of truth

- Data file: `Sources/Chord/AppShortcuts/firefox-zen-shortcuts.json`
- Loader / validation / cheat-sheet derivation: `Sources/Chord/AppShortcuts/BrowserShortcutCatalogue.swift`
- UI: **Firefox / Zen Shortcuts…** in the menubar popover when Firefox or Zen is frontmost

Do **not** hard-code shortcut strings in the SwiftUI view. Edit the JSON, then regenerate understanding from `keep: true` records.

## Record schema

Each record includes: `id`, `action`, `category`, `browser`, `keys`, `availability`, `sourceUrl`, `sourceCheckedAt`, `notes`, `keep`, `keepReason`.

- `browser`: `firefox` | `zen` | `both` (only when the same action **and** binding were verified in both)
- `availability`: `default` | `version-dependent` | `conflict` | `unverified`
- Cheat sheet includes only `keep: true` with `availability: default`

## Refreshing after a browser update

1. Note installed versions:
   ```bash
   defaults read /Applications/Firefox.app/Contents/Info.plist CFBundleShortVersionString
   defaults read /Applications/Zen.app/Contents/Info.plist CFBundleShortVersionString
   ```
2. Re-check official sources:
   - Firefox: https://support.mozilla.org/en-US/kb/keyboard-shortcuts-perform-firefox-tasks-quickly
   - Zen: https://docs.zen-browser.app/user-manual/shortcuts
3. Cross-check Zen in-product defaults when docs look cross-platform (`Ctrl` tables often mean accel):
   ```bash
   unzip -p /Applications/Zen.app/Contents/Resources/browser/omni.ja \
     chrome/browser/content/browser/zen-components/ZenKeyboardShortcuts.mjs \
     | less
   ```
4. Update `browsersChecked`, `sourceCheckedAt`, and any changed records in the JSON.
5. Re-apply trimming rules (`keep` / `keepReason`) — target **12–20** retained shortcuts.
6. Run:
   ```bash
   swift test --filter BrowserShortcutCatalogueTests
   ```
7. Manually spot-check retained bindings in both apps; record results in `docs/firefox-zen-shortcuts-manual-verification.md`.

## Packaging note

`scripts/build.sh` copies `firefox-zen-shortcuts.json` into the app Resources so the packaged menubar app can load the catalogue outside SwiftPM’s `Bundle.module`.
