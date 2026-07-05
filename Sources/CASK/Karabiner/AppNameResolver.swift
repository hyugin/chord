import AppKit

enum AppNameResolver {
  static func title(for bundlePattern: String) -> String {
    for app in NSWorkspace.shared.runningApplications {
      guard let bundleID = app.bundleIdentifier,
            RegexMatcher.matches(pattern: bundlePattern, in: bundleID),
            let name = app.localizedName else {
        continue
      }
      return name
    }

    return prettifyPattern(bundlePattern)
  }

  static func prettifyPattern(_ pattern: String) -> String {
    var text = pattern
    if text.hasPrefix("^") {
      text.removeFirst()
    }
    if text.hasSuffix("$") {
      text.removeLast()
    }

    text = text.replacingOccurrences(of: "\\.", with: ".")

    if let lastComponent = text.split(separator: ".").last, !lastComponent.isEmpty {
      return String(lastComponent)
    }

    return pattern
  }
}
