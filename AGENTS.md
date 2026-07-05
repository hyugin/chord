# AGENTS.md

## Cursor Cloud specific instructions

CASK is a **macOS-only** SwiftUI/AppKit menu bar app (`Package.swift` targets `.macOS(.v13)`). It **cannot be fully built, run, or tested on the Linux Cursor Cloud VM** because it depends on Apple-only frameworks (`AppKit`, `SwiftUI`, `Combine`, `Darwin`). A full build/run and the real `swift test` suite require **macOS + Xcode**; CI runs on `macos-26` (see `.github/workflows/release.yaml`). Standard commands live in `README.md` and `mise.toml` (`swift run`, `swift build -c release`, `./scripts/build.sh`, `swift test`).

### Swift toolchain on Linux
- Swift for Linux is installed via `swiftly` and captured in the VM snapshot. In a non-login shell it may not be on `PATH`; source it first: `. "$HOME/.local/share/swiftly/env.sh"`.
- Package-level `swift build` / `swift test` fail on Linux with `no such module 'AppKit'/'SwiftUI'/'Combine'`. This is expected on this platform, not a regression.

### Exercising core logic on Linux (no macOS needed)
- The Karabiner logic under `Sources/CASK/Karabiner/` and `Sources/CASK/KeyboardMap/` is pure `Foundation` and compiles on Linux — **except** `Karabiner/BindingMatcher.swift` and `Karabiner/AppNameResolver.swift`, which import `AppKit`.
- To smoke-test the core pipeline, compile the Foundation-only files with `swiftc` alongside a small driver and load `Tests/CASKTests/Fixtures/karabiner.json` via `KarabinerLoader`, then run `KarabinerShortcutExtractor.extract(...)`. This exercises config parsing, scope classification, key formatting, and warnings without any Apple frameworks.
- The XCTest suite in `Tests/CASKTests` still requires macOS because the test target links the whole `CASK` module (which imports AppKit).
