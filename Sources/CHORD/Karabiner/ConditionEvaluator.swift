import Foundation

enum ConditionEvaluator {
  static func conditionsSatisfied(
    _ conditions: [KarabinerConfig.Condition]?,
    bundleIdentifier: String?
  ) -> Bool {
    guard let conditions, !conditions.isEmpty else { return true }

    for condition in conditions {
      switch condition.type {
      case "frontmost_application_if":
        guard let bundleIdentifier else { return false }
        guard let patterns = condition.bundleIdentifiers, !patterns.isEmpty else { return false }
        let matches = patterns.contains {
          RegexMatcher.matches(pattern: $0, in: bundleIdentifier)
        }
        if !matches { return false }

      case "frontmost_application_unless":
        guard let bundleIdentifier else { continue }
        guard let patterns = condition.bundleIdentifiers, !patterns.isEmpty else { continue }
        let excluded = patterns.contains {
          RegexMatcher.matches(pattern: $0, in: bundleIdentifier)
        }
        if excluded { return false }

      default:
        continue
      }
    }

    return true
  }

  static func frontmostApplicationIfPatterns(
    in conditions: [KarabinerConfig.Condition]?
  ) -> [String] {
    conditions?
      .filter { $0.type == "frontmost_application_if" }
      .compactMap(\.bundleIdentifiers)
      .flatMap { $0 } ?? []
  }

  static func isAppScoped(_ conditions: [KarabinerConfig.Condition]?) -> Bool {
    !frontmostApplicationIfPatterns(in: conditions).isEmpty
  }

  static func matchesCurrentApp(
    conditions: [KarabinerConfig.Condition]?,
    bundleIdentifier: String
  ) -> Bool {
    let patterns = frontmostApplicationIfPatterns(in: conditions)
    guard !patterns.isEmpty else { return false }
    return patterns.contains {
      RegexMatcher.matches(pattern: $0, in: bundleIdentifier)
    }
  }
}
