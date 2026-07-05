import Foundation

enum KarabinerShortcutExtractor {
  static func extract(from config: KarabinerConfig) -> ShortcutExtractionResult {
    guard let profile = config.selectedProfile else {
      return ShortcutExtractionResult(shortcuts: [], warnings: ["No profile selected"])
    }

    let rules = profile.complexModifications?.rules ?? []
    var shortcuts: [KarabinerShortcut] = []
    var warnings: [String] = []

    for (ruleIndex, rule) in rules.enumerated() {
      for (manipulatorIndex, manipulator) in (rule.manipulators ?? []).enumerated() {
        let result = extractShortcut(
          rule: rule,
          manipulator: manipulator,
          ruleIndex: ruleIndex,
          manipulatorIndex: manipulatorIndex
        )

        if let shortcut = result.shortcut {
          shortcuts.append(shortcut)
        }
        warnings.append(contentsOf: result.warnings)
      }
    }

    return ShortcutExtractionResult(
      shortcuts: shortcuts,
      warnings: Array(Set(warnings)).sorted()
    )
  }

  private static func extractShortcut(
    rule: KarabinerConfig.Rule,
    manipulator: KarabinerConfig.Manipulator,
    ruleIndex: Int,
    manipulatorIndex: Int
  ) -> (shortcut: KarabinerShortcut?, warnings: [String]) {
    var warnings: [String] = []

    if let simultaneous = manipulator.from?.simultaneous, !simultaneous.isEmpty {
      warnings.append("Simultaneous key input not visualized (rule \(ruleIndex + 1))")
    }

    let scopeResult = classifyScope(conditions: manipulator.conditions)
    warnings.append(contentsOf: scopeResult.warnings)

    guard let trigger = KeyFormatter.parseTrigger(from: manipulator.from) else {
      return (nil, warnings)
    }

    let keys = trigger.displayText
    let rawLabel = label(for: rule, keys: keys)
    let displayLabel = BindingLabelFormatter.displayLabel(label: rawLabel, keys: keys)
    let actions = summarizeActions(manipulator: manipulator)
    let isHyperLayer = detectHyperLayerActivator(
      trigger: trigger,
      rule: rule,
      manipulator: manipulator
    )

    let finalTrigger = KeyTrigger(
      keyCode: trigger.keyCode,
      mandatoryModifiers: trigger.mandatoryModifiers,
      optionalModifiers: trigger.optionalModifiers,
      isHyper: trigger.isHyper,
      displayText: trigger.displayText,
      isLayerActivator: trigger.isLayerActivator || isHyperLayer
    )

    let supported: Bool
    if case .unknown = scopeResult.scope {
      supported = false
    } else {
      supported = true
    }
    let warningNote = warnings.isEmpty ? nil : warnings.joined(separator: "; ")

    let shortcut = KarabinerShortcut(
      id: "\(ruleIndex)-\(manipulatorIndex)-\(finalTrigger.displayText)",
      sourceRuleDescription: rule.description,
      displayLabel: displayLabel,
      trigger: finalTrigger,
      actions: actions,
      scope: scopeResult.scope,
      conditions: manipulator.conditions ?? [],
      sourceRuleIndex: ruleIndex,
      sourceManipulatorIndex: manipulatorIndex,
      supported: supported,
      warningNote: warningNote
    )

    return (shortcut, warnings)
  }

  private static func classifyScope(
    conditions: [KarabinerConfig.Condition]?
  ) -> (scope: ShortcutScope, warnings: [String]) {
    guard let conditions, !conditions.isEmpty else {
      return (.global, [])
    }

    var warnings: [String] = []
    var ifPatterns: [String] = []
    var unlessPatterns: [String] = []
    var variableLayers: [(name: String?, description: String?)] = []
    var unknownTypes: [String] = []

    for condition in conditions {
      switch condition.type {
      case "frontmost_application_if":
        ifPatterns.append(contentsOf: condition.bundleIdentifiers ?? [])
      case "frontmost_application_unless":
        unlessPatterns.append(contentsOf: condition.bundleIdentifiers ?? [])
      case "variable_if", "variable_unless":
        variableLayers.append((condition.name, condition.description))
      default:
        if let type = condition.type {
          unknownTypes.append(type)
        }
      }
    }

    if !unknownTypes.isEmpty {
      warnings.append("Unsupported condition types: \(unknownTypes.joined(separator: ", "))")
    }

    if !variableLayers.isEmpty {
      let layer = variableLayers[0]
      return (
        .variableLayer(
          name: layer.name,
          description: layer.description,
          ifPatterns: ifPatterns,
          unlessPatterns: unlessPatterns
        ),
        warnings
      )
    }

    if !ifPatterns.isEmpty {
      return (.appSpecific(patterns: ifPatterns), warnings)
    }

    if !unlessPatterns.isEmpty {
      return (.excludedApps(patterns: unlessPatterns), warnings)
    }

    if !unknownTypes.isEmpty {
      return (.unknown(summary: unknownTypes.joined(separator: ", ")), warnings)
    }

    return (.global, warnings)
  }

  private static func detectHyperLayerActivator(
    trigger: KeyTrigger,
    rule: KarabinerConfig.Rule,
    manipulator: KarabinerConfig.Manipulator
  ) -> Bool {
    guard trigger.keyCode == "caps_lock" else { return false }

    let description = rule.description?.lowercased() ?? ""
    if description.contains("hyper") {
      return true
    }

    return allToEvents(from: manipulator).contains { event in
      event.setVariable?.name?.lowercased().contains("hyper") == true
    }
  }

  private static func allToEvents(from manipulator: KarabinerConfig.Manipulator) -> [KarabinerConfig.ToEvent] {
    var events = manipulator.to ?? []
    events.append(contentsOf: manipulator.toIfAlone ?? [])
    events.append(contentsOf: manipulator.toIfHeldDown ?? [])
    events.append(contentsOf: manipulator.toAfterKeyUp ?? [])
    if let delayed = manipulator.toDelayedAction {
      events.append(contentsOf: delayed.toIfInvoked ?? [])
      events.append(contentsOf: delayed.toIfCanceled ?? [])
    }
    return events
  }

  private static func summarizeActions(manipulator: KarabinerConfig.Manipulator) -> [KarabinerAction] {
    var actions: [KarabinerAction] = []

    appendActionSummaries(from: manipulator.to, prefix: nil, into: &actions)
    appendActionSummaries(from: manipulator.toIfAlone, prefix: "If alone:", into: &actions)
    appendActionSummaries(from: manipulator.toIfHeldDown, prefix: "If held:", into: &actions)
    appendActionSummaries(from: manipulator.toAfterKeyUp, prefix: "After key up:", into: &actions)

    if let delayed = manipulator.toDelayedAction {
      appendActionSummaries(from: delayed.toIfInvoked, prefix: "Delayed:", into: &actions)
      appendActionSummaries(from: delayed.toIfCanceled, prefix: "Delayed cancel:", into: &actions)
    }

    return actions
  }

  private static func appendActionSummaries(
    from events: [KarabinerConfig.ToEvent]?,
    prefix: String?,
    into actions: inout [KarabinerAction]
  ) {
    for event in events ?? [] {
      if let summary = summarize(event: event, prefix: prefix) {
        actions.append(KarabinerAction(summary: summary))
      }
    }
  }

  private static func summarize(event: KarabinerConfig.ToEvent, prefix: String?) -> String? {
    var parts: [String] = []

    if let prefix {
      parts.append(prefix)
    }

    if let shell = event.shellCommand {
      parts.append("shell: \(shell)")
    } else if let variable = event.setVariable {
      let name = variable.name ?? "variable"
      let value = variable.value.map(String.init) ?? "?"
      parts.append("set \(name)=\(value)")
    } else if let keyCode = event.keyCode {
      parts.append("key: \(KeyFormatter.keyLabel(for: keyCode))")
    } else if let consumer = event.consumerKeyCode {
      parts.append("consumer: \(consumer)")
    }

    if parts.isEmpty {
      return nil
    }

    return parts.joined(separator: " ")
  }

  private static func label(for rule: KarabinerConfig.Rule, keys: String) -> String {
    if let description = rule.description?.trimmingCharacters(in: .whitespacesAndNewlines),
       !description.isEmpty {
      return description
    }
    return keys
  }
}
