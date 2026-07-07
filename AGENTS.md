# AGENTS.md

## Cursor Cloud specific instructions

Chord (the SwiftPM product and module are named `Chord`; earlier drafts called it CASK) is a **macOS-only** SwiftUI/AppKit menu bar app (`Package.swift` targets `.macOS(.v13)`). It **cannot be fully built, run, or tested on the Linux Cursor Cloud VM** because it depends on Apple-only frameworks (`AppKit`, `SwiftUI`, `Combine`, `Darwin`). A full build/run and the real `swift test` suite require **macOS + Xcode**; CI runs on `macos-26` (see `.github/workflows/release.yaml`). Standard commands live in `README.md` and `mise.toml` (`swift run`, `swift build -c release`, `./scripts/build.sh`, `swift test`).

### Swift toolchain on Linux
- Swift for Linux is provided by the Cursor Cloud update script via `swiftly` (installed under `$HOME/.local/share/swiftly`). In a non-login shell it is not on `PATH`; source it first: `. "$HOME/.local/share/swiftly/env.sh"`.
- Package-level `swift build` / `swift test` fail on Linux with `no such module 'AppKit'/'SwiftUI'/'Combine'`. This is expected on this platform, not a regression.

### Exercising core logic on Linux (no macOS needed)
- The Karabiner logic under `Sources/Chord/Karabiner/` and `Sources/Chord/KeyboardMap/` is pure `Foundation` and compiles on Linux with `swiftc`, **except** these three files: `Karabiner/AppNameResolver.swift` (imports `AppKit`), `Karabiner/KarabinerConfigWatcher.swift` (imports `Darwin`), and `Karabiner/BindingMatcher.swift` (Foundation-only itself but calls `AppNameResolver`, so it will not compile standalone). Exclude those three when compiling the core pipeline.
- To smoke-test the core pipeline, compile the remaining Foundation-only files with `swiftc` alongside a small driver, load `Tests/ChordTests/Fixtures/karabiner.json` via `KarabinerLoader`, then run `KarabinerShortcutExtractor.extract(...)`. This exercises config parsing, scope classification, key formatting, and warnings without any Apple frameworks (verified: it extracts 7 shortcuts from the fixture).
- The XCTest suite in `Tests/ChordTests` still requires macOS because the test target links the whole `Chord` module (which imports AppKit).
