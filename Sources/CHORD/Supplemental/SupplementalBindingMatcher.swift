import Foundation

enum SupplementalBindingMatcher {
  private static let thinSpace = "\u{2009}"
  private static let modifierSymbols: Set<Character> = ["⌘", "⇧", "⌥", "⌃", "⇪"]

  static func bindings(
    for bundleIdentifier: String?,
    from entries: [SupplementalBindingEntry]
  ) -> [Binding] {
    entries.compactMap { entry in
      binding(for: entry, frontmostBundleIdentifier: bundleIdentifier)
    }
  }

  static func normalizeKeys(_ keys: String) -> String {
    let trimmed = keys.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.contains(thinSpace),
          let last = trimmed.last,
          last.isLetter || last.isNumber
    else {
      return trimmed
    }

    let prefix = String(trimmed.dropLast())
    guard !prefix.isEmpty, prefix.allSatisfy({ modifierSymbols.contains($0) }) else {
      return trimmed
    }

    return prefix + thinSpace + String(last)
  }

  private static func binding(
    for entry: SupplementalBindingEntry,
    frontmostBundleIdentifier: String?
  ) -> Binding? {
    let keys = normalizeKeys(entry.keys)
    let label = entry.label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !keys.isEmpty, !label.isEmpty else { return nil }

    if let required = entry.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
       !required.isEmpty {
      guard let frontmostBundleIdentifier,
            matches(required: required, frontmost: frontmostBundleIdentifier)
      else {
        return nil
      }

      return Binding(
        label: label,
        keys: keys,
        scope: .app(bundleIdentifier: required)
      )
    }

    return Binding(label: label, keys: keys, scope: .global)
  }

  private static func matches(required: String, frontmost: String) -> Bool {
    frontmost == required
      || RegexMatcher.matches(pattern: required, in: frontmost)
  }
}
