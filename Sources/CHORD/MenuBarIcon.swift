import AppKit

enum MenuBarIcon {
  private static let defaultSymbolName = "command"

  private static var symbolName: String {
    guard
      let fromEnvironment = ProcessInfo.processInfo.environment["CHORD_MENUBAR_ICON"]?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !fromEnvironment.isEmpty
    else {
      return defaultSymbolName
    }
    return fromEnvironment
  }

  static func makeImage() -> NSImage {
    let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

    for name in [symbolName, defaultSymbolName] {
      guard
        let symbol = NSImage(systemSymbolName: name, accessibilityDescription: "CHORD"),
        let configured = symbol.withSymbolConfiguration(configuration)
      else {
        continue
      }

      configured.isTemplate = true
      return configured
    }

    return NSImage()
  }
}
