import Foundation

struct Binding: Identifiable, Hashable {
  enum Scope: Hashable {
    case global
    case app(bundleIdentifier: String)
  }

  let id: String
  let label: String
  let keys: String
  let scope: Scope

  init(label: String, keys: String, scope: Scope) {
    self.label = label
    self.keys = keys
    self.scope = scope
    self.id = "\(scope)-\(keys)-\(label)"
  }
}

struct BindingGroup: Identifiable, Hashable {
  let id: String
  let title: String
  let bindings: [Binding]
}
