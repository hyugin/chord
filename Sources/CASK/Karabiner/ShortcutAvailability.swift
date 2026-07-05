import Foundation

enum ShortcutAvailability {
  static func matchesScope(_ shortcut: KarabinerShortcut, filter: ScopeFilter) -> Bool {
    switch filter {
    case .all:
      return true
    case .global:
      if case .global = shortcut.scope { return true }
      if case .excludedApps = shortcut.scope { return true }
      return false
    case .currentApp(let bundleIdentifier):
      guard let bundleIdentifier else { return false }
      return matchesCurrentApp(shortcut: shortcut, bundleIdentifier: bundleIdentifier)
    }
  }

  static func matchesCurrentApp(shortcut: KarabinerShortcut, bundleIdentifier: String) -> Bool {
    switch shortcut.scope {
    case .global:
      return true
    case .appSpecific(let patterns):
      return patterns.contains { RegexMatcher.matches(pattern: $0, in: bundleIdentifier) }
    case .excludedApps(let patterns):
      let excluded = patterns.contains { RegexMatcher.matches(pattern: $0, in: bundleIdentifier) }
      return !excluded
    case .variableLayer(_, _, let ifPatterns, let unlessPatterns):
      if !ifPatterns.isEmpty {
        return ifPatterns.contains { RegexMatcher.matches(pattern: $0, in: bundleIdentifier) }
      }
      if !unlessPatterns.isEmpty {
        let excluded = unlessPatterns.contains { RegexMatcher.matches(pattern: $0, in: bundleIdentifier) }
        return !excluded
      }
      return true
    case .unknown:
      return true
    }
  }

  static func normalizedTriggerKey(_ trigger: KeyTrigger) -> String? {
    guard let keyCode = trigger.keyCode else { return nil }
    return keyCode.lowercased()
  }

  static func isAvailable(
    keyCode: String,
    shortcuts: [KarabinerShortcut],
    filter: KeyboardMapFilter
  ) -> Bool {
    let matching = shortcuts.filter { shortcut in
      guard matchesScope(shortcut, filter: filter.scopeFilter) else { return false }
      guard KeyFormatter.matchesModifierFilter(shortcut.trigger, filter: filter.modifierFilter) else {
        return false
      }
      return shortcut.trigger.keyCode?.lowercased() == keyCode.lowercased()
    }

    return matching.isEmpty
  }
}
