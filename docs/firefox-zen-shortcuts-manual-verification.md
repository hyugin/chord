# Manual verification — Firefox / Zen shortcuts (macOS)

Date: 2026-07-23  
Catalogue version: 2026.07.23

## Browsers

| Browser | Version | Bundle ID |
| --- | --- | --- |
| Firefox | 153.0 | `org.mozilla.firefox` |
| Zen | 1.21.8b | `app.zen-browser.zen` |

## Source verification (completed without interactive keypresses)

| Source | Result |
| --- | --- |
| Mozilla Firefox Help shortcuts page | Cited for shared macOS bindings (`command` / `command+shift` / `command+alt`) via official Help excerpts + Firefox 153.0 `browser.xhtml` / `browserSets.ftl` keysets in the app bundle |
| Zen docs shortcuts page | Cited for Zen-specific features; several table rows still use cross-platform `Ctrl`/`Alt+Ctrl` notation |
| Zen 1.21.8b `ZenKeyboardShortcuts.mjs` | Confirmed in-product defaults where docs diverge (workspaces arrows, compact `accel+S`, markdown copy `accel+shift+alt+C`) |
| Automated suite | `swift test` — 56/56 passed on 2026-07-23, including `BrowserShortcutCatalogueTests` |

Interactive pass/fail below is still recommended once before shipping habit-level confidence.

## Retained cheat-sheet bindings

Manual pass/fail is for a normal profile with **default** shortcuts (no remaps, no conflicting extensions).

| Action | Keys | Firefox 153.0 | Zen 1.21.8b | Notes |
| --- | --- | --- | --- | --- |
| New Tab | ⌘T | pending | pending | |
| Close Tab | ⌘W | pending | pending | |
| Reopen Closed Tab | ⇧⌘T | pending | pending | |
| New Window | ⌘N | pending | pending | |
| New Private Window | ⇧⌘P | pending | pending | |
| Focus Address Bar | ⌘L | pending | pending | |
| Reload Page | ⌘R | pending | pending | |
| Go Back | ⌘[ | pending | pending | |
| Find in Page | ⌘F | pending | pending | |
| Focus Search | ⌘K | pending | pending | |
| Toggle Developer Tools | ⌥⌘I | pending | pending | |
| Web Console | ⌥⌘K | pending | pending | |
| Toggle Floating Sidebar | ⌥⌘S | n/a | pending | Zen-only |
| Forward Workspace | ⌥⌘→ | n/a | pending | Zen-only |
| Toggle Split View Horizontal | ⌥⌘H | n/a | pending | Zen-only |
| Copy Current URL as Markdown | ⌥⇧⌘C | n/a | pending | Zen-only |

## Known conflicts / doc deltas (excluded from cheat sheet)

| Item | Status |
| --- | --- |
| Save Page `⌘S` vs Zen Compact Mode toggle in-product `⌘S` | `availability: conflict` — excluded |
| Zen docs Compact Mode `⌃⌥C` vs in-product `⌘S` | `version-dependent` — excluded until remapped/clarified |
| Zen Inspector remapped to `⌥⌘L` | `version-dependent` — documented, not retained |

## How to complete the pending cells

1. Launch Firefox 153 / Zen 1.21.8b on macOS.
2. For each retained row, focus the browser and press the listed keys.
3. Mark **pass** if the documented action occurs; **fail** if not.
4. On fail: set the catalogue record to `unverified` or `conflict`, clear `keep`, add a note, re-run `BrowserShortcutCatalogueTests`.
