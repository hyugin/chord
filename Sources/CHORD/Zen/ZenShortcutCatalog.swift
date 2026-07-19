import Foundation

/// Non-Karabiner shortcuts that Chord should surface when Zen is frontmost.
///
/// These are app-level or userscript chords that never appear in `karabiner.json`.
enum ZenShortcutCatalog {
  static let bundleIdentifier = "app.zen-browser.zen"

  private static let thinSpace = "\u{2009}"

  static func bindings(for bundleIdentifier: String?) -> [Binding] {
    guard let bundleIdentifier, isZen(bundleIdentifier) else { return [] }

    return [
      Binding(
        label: "Notion | Toggle tab lock (launcher)",
        keys: "⌘⇧\(thinSpace)L",
        scope: .app(bundleIdentifier: Self.bundleIdentifier)
      ),
    ]
  }

  private static func isZen(_ bundleIdentifier: String) -> Bool {
    bundleIdentifier == Self.bundleIdentifier
      || RegexMatcher.matches(pattern: "^app\\.zen-browser\\.zen$", in: bundleIdentifier)
  }
}
