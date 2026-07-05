import Foundation

enum BindingLabelFormatter {
  static func displayLabel(label: String, keys: String) -> String {
    if keys == "Caps Lock", label.lowercased().contains("hyper key") {
      return "Hyper layer key"
    }

    var text = label

    if let range = text.range(of: " | ") {
      text = String(text[range.upperBound...])
    }

    for arrow in [" → ", " -> ", "→", "->"] {
      if let range = text.range(of: arrow) {
        text = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        break
      }
    }

    text = stripTrailingShortcutHint(text)

    return text.isEmpty ? label : text
  }

  private static func stripTrailingShortcutHint(_ text: String) -> String {
    guard let open = text.lastIndex(of: "("),
          text.hasSuffix(")"),
          open > text.startIndex
    else { return text }

    let hint = text[text.index(after: open)..<text.index(before: text.endIndex)]
    guard looksLikeShortcutHint(String(hint)) else { return text }

    return String(text[..<open]).trimmingCharacters(in: .whitespaces)
  }

  private static func looksLikeShortcutHint(_ hint: String) -> Bool {
    let lowered = hint.lowercased()
    let keywords = [
      "cmd", "ctrl", "control", "option", "opt", "shift", "hyper",
      "⌘", "⌃", "⌥", "⇧", "command",
    ]

    if keywords.contains(where: { lowered.contains($0) }) {
      return true
    }

    return hint.contains("+")
  }
}
