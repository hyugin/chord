import Foundation

struct KeyTrigger: Hashable {
  let keyCode: String?
  let mandatoryModifiers: [String]
  let optionalModifiers: [String]
  let isHyper: Bool
  let displayText: String
  let isLayerActivator: Bool
}

enum ShortcutScope: Hashable {
  case global
  case appSpecific(patterns: [String])
  case excludedApps(patterns: [String])
  case variableLayer(
    name: String?,
    description: String?,
    ifPatterns: [String],
    unlessPatterns: [String]
  )
  case unknown(summary: String)
}

struct KarabinerAction: Hashable {
  let summary: String
}

struct KarabinerShortcut: Identifiable, Hashable {
  let id: String
  let sourceRuleDescription: String?
  let displayLabel: String
  let trigger: KeyTrigger
  let actions: [KarabinerAction]
  let scope: ShortcutScope
  let conditions: [KarabinerConfig.Condition]
  let sourceRuleIndex: Int
  let sourceManipulatorIndex: Int
  let supported: Bool
  let warningNote: String?
}

struct ShortcutExtractionResult: Hashable {
  let shortcuts: [KarabinerShortcut]
  let warnings: [String]
}

enum ModifierLayerFilter: String, CaseIterable, Identifiable {
  case none = "None"
  case command = "Command"
  case option = "Option"
  case control = "Control"
  case shift = "Shift"
  case hyper = "Hyper"

  var id: String { rawValue }
}

enum ScopeFilter: Hashable {
  case all
  case global
  case currentApp(bundleIdentifier: String?)
}

struct KeyboardMapFilter: Hashable {
  var scopeFilter: ScopeFilter = .all
  var modifierFilter: ModifierLayerFilter = .hyper
  var showOccupied = true
  var showAvailable = true
  var showAmbiguous = true
}
