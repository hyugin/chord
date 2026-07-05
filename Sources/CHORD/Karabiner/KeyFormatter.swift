import Foundation

enum KeyFormatter {
  private static let thinSpace = "\u{2009}"

  private static let modifierSymbols: [String: String] = [
    "command": "⌘",
    "control": "⌃",
    "option": "⌥",
    "shift": "⇧",
    "caps_lock": "⇪",
  ]

  private static let modifierOrder = ["command", "shift", "option", "control"]

  private static let hyperModifierKinds: Set<String> = ["command", "control", "option", "shift"]

  private static let keyCodeLabels: [String: String] = [
    "spacebar": "Space",
    "return_or_enter": "Return",
    "tab": "Tab",
    "delete_or_backspace": "Delete",
    "delete_forward": "Fwd Delete",
    "escape": "Esc",
    "up_arrow": "↑",
    "down_arrow": "↓",
    "left_arrow": "←",
    "right_arrow": "→",
    "page_up": "PgUp",
    "page_down": "PgDn",
    "home": "Home",
    "end": "End",
    "f1": "F1",
    "f2": "F2",
    "f3": "F3",
    "f4": "F4",
    "f5": "F5",
    "f6": "F6",
    "f7": "F7",
    "f8": "F8",
    "f9": "F9",
    "f10": "F10",
    "f11": "F11",
    "f12": "F12",
    "caps_lock": "Caps Lock",
    "hyphen": "-",
    "equal_sign": "=",
    "open_bracket": "[",
    "close_bracket": "]",
    "backslash": "\\",
    "semicolon": ";",
    "quote": "'",
    "comma": ",",
    "period": ".",
    "slash": "/",
    "grave_accent_and_tilde": "`",
  ]

  static func parseTrigger(from event: KarabinerConfig.FromEvent?) -> KeyTrigger? {
    guard let event else { return nil }

    let mandatory = normalizedModifierKinds(event.modifiers?.mandatory ?? [])
    let optional = normalizedModifierKinds(event.modifiers?.optional ?? [])
    let counts = modifierKindCounts(mandatory)
    let hyper = isHyper(counts)
    let display = format(from: event) ?? ""
    let layerActivator = event.keyCode == "caps_lock" && mandatory.isEmpty

    guard event.keyCode != nil || !mandatory.isEmpty else { return nil }

    return KeyTrigger(
      keyCode: event.keyCode,
      mandatoryModifiers: mandatory,
      optionalModifiers: optional,
      isHyper: hyper,
      displayText: display,
      isLayerActivator: layerActivator
    )
  }

  static func normalizedModifierKinds(_ modifiers: [String]) -> [String] {
    modifiers.compactMap { modifierKind(for: $0) }
  }

  static func isHyper(modifiers: [String]) -> Bool {
    isHyper(modifierKindCounts(normalizedModifierKinds(modifiers)))
  }

  static func matchesModifierFilter(_ trigger: KeyTrigger, filter: ModifierLayerFilter) -> Bool {
    switch filter {
    case .none:
      return trigger.mandatoryModifiers.isEmpty && !trigger.isHyper
    case .command:
      return trigger.mandatoryModifiers.contains("command") && !trigger.isHyper
    case .option:
      return trigger.mandatoryModifiers.contains("option") && !trigger.isHyper
    case .control:
      return trigger.mandatoryModifiers.contains("control") && !trigger.isHyper
    case .shift:
      return trigger.mandatoryModifiers.contains("shift") && !trigger.isHyper
    case .hyper:
      return trigger.isHyper
    }
  }

  static func format(from event: KarabinerConfig.FromEvent?) -> String? {
    guard let event else { return nil }

    let mandatory = event.modifiers?.mandatory ?? []
    let modifierCounts = modifierKindCounts(mandatory)

    guard let keyCode = event.keyCode else {
      let symbols = orderedModifierSymbols(counts: modifierCounts)
      return symbols.isEmpty ? nil : symbols.joined()
    }

    let keyPart = keyLabel(for: keyCode)

    if isHyper(modifierCounts) {
      let extraCounts = hyperExtraModifierCounts(modifierCounts)
      let extraSymbols = orderedModifierSymbols(counts: extraCounts)
      if extraSymbols.isEmpty {
        return "Hyper+\(keyPart)"
      }
      return "Hyper+\(extraSymbols.joined())+\(keyPart)"
    }

    let modifierPart = orderedModifierSymbols(counts: modifierCounts).joined()
    if modifierPart.isEmpty {
      return keyPart
    }
    return modifierPart + thinSpace + keyPart
  }

  static func keyLabel(for keyCode: String) -> String {
    if let label = keyCodeLabels[keyCode] {
      return label
    }

    if keyCode.count == 1, let character = keyCode.first, character.isLetter {
      return String(character).uppercased()
    }

    if keyCode.count == 1, keyCode.first?.isNumber == true {
      return keyCode
    }

    return keyCode
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }

  private static func modifierKind(for raw: String) -> String? {
    if raw.contains("command") { return "command" }
    if raw.contains("control") { return "control" }
    if raw.contains("option") { return "option" }
    if raw.contains("shift") { return "shift" }
    if raw == "caps_lock" { return "caps_lock" }
    return nil
  }

  private static func modifierKindCounts(_ modifiers: [String]) -> [String: Int] {
    modifiers.reduce(into: [:]) { counts, raw in
      guard let kind = modifierKind(for: raw) else { return }
      counts[kind, default: 0] += 1
    }
  }

  private static func isHyper(_ counts: [String: Int]) -> Bool {
    hyperModifierKinds.allSatisfy { (counts[$0] ?? 0) >= 1 }
  }

  private static func hyperExtraModifierCounts(_ counts: [String: Int]) -> [String: Int] {
    var extras: [String: Int] = [:]
    for kind in hyperModifierKinds {
      let extra = (counts[kind] ?? 0) - 1
      if extra > 0 {
        extras[kind] = extra
      }
    }
    for (kind, count) in counts where !hyperModifierKinds.contains(kind) {
      extras[kind] = count
    }
    return extras
  }

  private static func orderedModifierSymbols(counts: [String: Int]) -> [String] {
    modifierOrder.flatMap { kind in
      guard let symbol = modifierSymbols[kind], let count = counts[kind], count > 0 else {
        return [String]()
      }
      return Array(repeating: symbol, count: count)
    }
  }
}
