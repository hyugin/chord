import Foundation

struct SupplementalBindingsFile: Codable, Equatable {
  var bindings: [SupplementalBindingEntry]
}

struct SupplementalBindingEntry: Codable, Equatable, Hashable {
  /// Display form, e.g. `⌘⇧L` or `⌘⇧ L` (thin space optional).
  var keys: String
  /// Human label; same style as Karabiner rule descriptions.
  var label: String
  /// When set, only shown for that frontmost app. Omit for global.
  var bundleIdentifier: String?
}
