import AppKit

enum MenuBarIcon {
  private static let symbolName = "capslock"

  static func makeImage() -> NSImage {
    let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
    guard
      let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "CASK"),
      let configured = symbol.withSymbolConfiguration(configuration)
    else {
      return NSImage()
    }

    configured.isTemplate = true
    return configured
  }
}
