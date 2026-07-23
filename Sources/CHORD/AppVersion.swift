import Foundation

enum AppVersion {
  /// Marketing version from the app bundle (`CFBundleShortVersionString`).
  /// Falls back to `"dev"` when running outside a packaged `.app` (e.g. `swift run`).
  static var marketing: String {
    let fromBundle = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let trimmed = fromBundle?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmed, !trimmed.isEmpty {
      return trimmed
    }
    return "dev"
  }
}
