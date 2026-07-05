import Foundation

enum BindingMatcher {
  static func bindings(
    for bundleIdentifier: String?,
    in config: KarabinerConfig
  ) -> [Binding] {
    guard let profile = config.selectedProfile else { return [] }

    let rules = profile.complexModifications?.rules ?? []
    var results: [Binding] = []

    for rule in rules {
      for manipulator in rule.manipulators ?? [] {
        guard let keys = KeyFormatter.format(from: manipulator.from) else { continue }
        guard let scope = scope(for: manipulator, bundleIdentifier: bundleIdentifier) else { continue }

        let label = label(for: rule, keys: keys)
        results.append(Binding(label: label, keys: keys, scope: scope))
      }
    }

    return deduplicated(results)
  }

  static func allBindingGroups(in config: KarabinerConfig) -> [BindingGroup] {
    guard let profile = config.selectedProfile else { return [] }

    let rules = profile.complexModifications?.rules ?? []
    var appGroups: [String: [Binding]] = [:]
    var globalBindings: [Binding] = []

    for rule in rules {
      for manipulator in rule.manipulators ?? [] {
        guard let keys = KeyFormatter.format(from: manipulator.from) else { continue }

        let label = label(for: rule, keys: keys)
        let ifPatterns = ConditionEvaluator.frontmostApplicationIfPatterns(in: manipulator.conditions)

        if !ifPatterns.isEmpty {
          for pattern in ifPatterns {
            let binding = Binding(
              label: label,
              keys: keys,
              scope: .app(bundleIdentifier: pattern)
            )
            appGroups[pattern, default: []].append(binding)
          }
        } else {
          globalBindings.append(
            Binding(label: label, keys: keys, scope: .global)
          )
        }
      }
    }

    var groups: [BindingGroup] = appGroups
      .map { pattern, bindings in
        BindingGroup(
          id: pattern,
          title: AppNameResolver.title(for: pattern),
          bindings: deduplicated(bindings)
        )
      }
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

    let dedupedGlobal = deduplicated(globalBindings)
    if !dedupedGlobal.isEmpty {
      groups.append(
        BindingGroup(
          id: "global",
          title: "Global",
          bindings: dedupedGlobal
        )
      )
    }

    return groups
  }

  private static func label(for rule: KarabinerConfig.Rule, keys: String) -> String {
    if let description = rule.description?.trimmingCharacters(in: .whitespacesAndNewlines),
       !description.isEmpty {
      return description
    }
    return keys
  }

  private static func scope(
    for manipulator: KarabinerConfig.Manipulator,
    bundleIdentifier: String?
  ) -> Binding.Scope? {
    guard ConditionEvaluator.conditionsSatisfied(
      manipulator.conditions,
      bundleIdentifier: bundleIdentifier
    ) else {
      return nil
    }

    if let bundleIdentifier,
       ConditionEvaluator.isAppScoped(manipulator.conditions),
       ConditionEvaluator.matchesCurrentApp(
         conditions: manipulator.conditions,
         bundleIdentifier: bundleIdentifier
       ) {
      return .app(bundleIdentifier: bundleIdentifier)
    }

    if ConditionEvaluator.isAppScoped(manipulator.conditions) {
      return nil
    }

    return .global
  }

  private static func deduplicated(_ bindings: [Binding]) -> [Binding] {
    var seen = Set<String>()
    var unique: [Binding] = []

    for binding in bindings {
      let key = "\(binding.scope)-\(binding.keys)-\(binding.label)"
      guard seen.insert(key).inserted else { continue }
      unique.append(binding)
    }

    return unique.sorted {
      if $0.keys == $1.keys {
        return $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending
      }
      return $0.keys.localizedCaseInsensitiveCompare($1.keys) == .orderedAscending
    }
  }
}
