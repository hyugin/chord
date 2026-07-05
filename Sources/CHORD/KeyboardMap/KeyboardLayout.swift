import Foundation

struct KeyboardKey: Identifiable, Hashable {
  let id: String
  let keyCode: String
  let displayLabel: String
  let width: CGFloat
}

struct KeyboardRow: Identifiable, Hashable {
  let id: String
  let keys: [KeyboardKey]
}

enum KeyboardCellState: Hashable {
  case layerActivator
  case occupied(count: Int)
  case available
  case ambiguous(warning: String)
  case hidden
}

struct KeyboardMapCell: Identifiable, Hashable {
  let id: String
  let key: KeyboardKey
  let state: KeyboardCellState
  let shortcuts: [KarabinerShortcut]
}

struct KeyboardMap: Hashable {
  let profileName: String
  let rows: [[KeyboardMapCell]]
  let warnings: [String]
  let totalShortcuts: Int
}

enum KeyboardLayout {
  static let usANSI: [KeyboardRow] = [
    row("fn", keys: [
      ("escape", "Esc", 1),
      ("f1", "F1", 1), ("f2", "F2", 1), ("f3", "F3", 1), ("f4", "F4", 1),
      ("f5", "F5", 1), ("f6", "F6", 1), ("f7", "F7", 1), ("f8", "F8", 1),
      ("f9", "F9", 1), ("f10", "F10", 1), ("f11", "F11", 1), ("f12", "F12", 1),
    ]),
    row("num", keys: [
      ("grave_accent_and_tilde", "`", 1),
      ("1", "1", 1), ("2", "2", 1), ("3", "3", 1), ("4", "4", 1),
      ("5", "5", 1), ("6", "6", 1), ("7", "7", 1), ("8", "8", 1),
      ("9", "9", 1), ("0", "0", 1), ("hyphen", "-", 1), ("equal_sign", "=", 1),
      ("delete_or_backspace", "Delete", 1.5),
    ]),
    row("top", keys: [
      ("tab", "Tab", 1.5),
      ("q", "Q", 1), ("w", "W", 1), ("e", "E", 1), ("r", "R", 1),
      ("t", "T", 1), ("y", "Y", 1), ("u", "U", 1), ("i", "I", 1),
      ("o", "O", 1), ("p", "P", 1), ("open_bracket", "[", 1),
      ("close_bracket", "]", 1), ("backslash", "\\", 1),
    ]),
    row("home", keys: [
      ("caps_lock", "Caps", 1.75),
      ("a", "A", 1), ("s", "S", 1), ("d", "D", 1), ("f", "F", 1),
      ("g", "G", 1), ("h", "H", 1), ("j", "J", 1), ("k", "K", 1),
      ("l", "L", 1), ("semicolon", ";", 1), ("quote", "'", 1),
      ("return_or_enter", "Return", 2),
    ]),
    row("bottom", keys: [
      ("shift", "Shift", 2.25),
      ("z", "Z", 1), ("x", "X", 1), ("c", "C", 1), ("v", "V", 1),
      ("b", "B", 1), ("n", "N", 1), ("m", "M", 1), ("comma", ",", 1),
      ("period", ".", 1), ("slash", "/", 1),
      ("right_shift", "Shift", 2.75),
    ]),
    row("space", keys: [
      ("left_control", "Ctrl", 1.25),
      ("left_option", "Opt", 1.25),
      ("left_command", "Cmd", 1.25),
      ("spacebar", "Space", 5),
      ("right_command", "Cmd", 1.25),
      ("right_option", "Opt", 1.25),
      ("left_arrow", "←", 1), ("down_arrow", "↓", 1),
      ("up_arrow", "↑", 1), ("right_arrow", "→", 1),
    ]),
  ]

  static func key(for keyCode: String) -> KeyboardKey? {
    for row in usANSI {
      if let key = row.keys.first(where: { $0.keyCode == keyCode }) {
        return key
      }
    }
    return nil
  }

  private static func row(_ id: String, keys: [(String, String, CGFloat)]) -> KeyboardRow {
    KeyboardRow(
      id: id,
      keys: keys.map { keyCode, label, width in
        KeyboardKey(
          id: keyCode,
          keyCode: keyCode,
          displayLabel: label,
          width: width
        )
      }
    )
  }
}
