import Foundation

enum BrowserShortcutCatalogueError: LocalizedError {
  case resourceMissing
  case decodingFailed(Error)
  case validationFailed([String])

  var errorDescription: String? {
    switch self {
    case .resourceMissing:
      return "Browser shortcut catalogue JSON is missing from the bundle."
    case .decodingFailed(let error):
      return "Failed to decode browser shortcut catalogue: \(error.localizedDescription)"
    case .validationFailed(let issues):
      return "Browser shortcut catalogue failed validation:\n" + issues.joined(separator: "\n")
    }
  }
}

enum BrowserShortcutCatalogue {
  static let resourceName = "firefox-zen-shortcuts"
  static let expectedPlatform = "macOS"

  static func load(from data: Data) throws -> BrowserShortcutCatalogueFile {
    let decoder = JSONDecoder()
    let catalogue: BrowserShortcutCatalogueFile
    do {
      catalogue = try decoder.decode(BrowserShortcutCatalogueFile.self, from: data)
    } catch {
      throw BrowserShortcutCatalogueError.decodingFailed(error)
    }

    let issues = validate(catalogue)
    guard issues.isEmpty else {
      throw BrowserShortcutCatalogueError.validationFailed(issues)
    }
    return catalogue
  }

  static func load(from url: URL) throws -> BrowserShortcutCatalogueFile {
    try load(from: Data(contentsOf: url))
  }

  static func load() throws -> BrowserShortcutCatalogueFile {
    guard let url = resolveJSONURL() else {
      throw BrowserShortcutCatalogueError.resourceMissing
    }
    return try load(from: url)
  }

  static func resolveJSONURL() -> URL? {
    #if SWIFT_PACKAGE
    if let url = Bundle.module.url(forResource: resourceName, withExtension: "json") {
      return url
    }
    #endif
    if let url = Bundle.main.url(forResource: resourceName, withExtension: "json") {
      return url
    }

    // Source-tree fallback for local `swift run` without packaged resources.
    let sourceSibling = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("\(resourceName).json")
    if FileManager.default.fileExists(atPath: sourceSibling.path) {
      return sourceSibling
    }
    return nil
  }

  static func validate(_ catalogue: BrowserShortcutCatalogueFile) -> [String] {
    var issues: [String] = []

    if catalogue.platform != expectedPlatform {
      issues.append("platform must be \(expectedPlatform), got \(catalogue.platform)")
    }

    if catalogue.records.isEmpty {
      issues.append("catalogue has no records")
    }

    var seenIDs = Set<String>()
    var seenTriples = Set<String>()

    for record in catalogue.records {
      if !isValidID(record.id) {
        issues.append("invalid id '\(record.id)' (expected lowercase kebab-case)")
      }
      if !seenIDs.insert(record.id).inserted {
        issues.append("duplicate id '\(record.id)'")
      }

      let triple = "\(record.browser.rawValue)|\(record.keys)|\(record.action)"
      if !seenTriples.insert(triple).inserted {
        issues.append("duplicate (browser, keys, action) '\(triple)'")
      }

      if record.sourceUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        issues.append("\(record.id): sourceUrl is required")
      }

      if record.keep {
        if record.availability != .default {
          issues.append("\(record.id): keep=true requires availability=default")
        }
        let reason = record.keepReason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if reason.isEmpty {
          issues.append("\(record.id): keep=true requires keepReason")
        }
      } else if let reason = record.keepReason, !reason.isEmpty {
        issues.append("\(record.id): keepReason must be empty/null unless keep=true")
      }
    }

    return issues
  }

  static func cheatSheet(from catalogue: BrowserShortcutCatalogueFile) -> [BrowserShortcutCheatSheetSection] {
    let kept = keptRecords(from: catalogue)

    return BrowserShortcutCheatSheetGroup.allCases.compactMap { group in
      let items = kept.filter { BrowserShortcutCheatSheetGroup.group(for: $0) == group }
      guard !items.isEmpty else { return nil }
      return BrowserShortcutCheatSheetSection(group: group, records: items)
    }
  }

  /// Kept shortcuts for the menubar app section (Firefox → shared+Firefox, Zen → shared+Zen).
  static func menuBindings(forBundleIdentifier bundleIdentifier: String?) -> [Binding] {
    guard let bundleIdentifier,
          let family = browserFamily(forBundleIdentifier: bundleIdentifier),
          let catalogue = try? load()
    else {
      return []
    }

    return keptRecords(from: catalogue, matching: family).map { record in
      Binding(
        label: record.action,
        keys: record.keys,
        scope: .app(bundleIdentifier: bundleIdentifier)
      )
    }
  }

  static func keptRecords(
    from catalogue: BrowserShortcutCatalogueFile,
    matching family: BrowserShortcutRecord.Browser? = nil
  ) -> [BrowserShortcutRecord] {
    catalogue.records.filter { record in
      guard record.keep,
            record.availability != .conflict,
            record.availability != .unverified
      else {
        return false
      }

      guard let family else { return true }

      switch family {
      case .firefox:
        return record.browser == .firefox || record.browser == .both
      case .zen:
        return record.browser == .zen || record.browser == .both
      case .both:
        return true
      }
    }
  }

  static func browserFamily(forBundleIdentifier bundleIdentifier: String?) -> BrowserShortcutRecord.Browser? {
    guard let bundleIdentifier else { return nil }
    if firefoxBundleIdentifiers.contains(bundleIdentifier) { return .firefox }
    if zenBundleIdentifiers.contains(bundleIdentifier) { return .zen }
    return nil
  }

  static func applies(toBundleIdentifier bundleIdentifier: String?) -> Bool {
    browserFamily(forBundleIdentifier: bundleIdentifier) != nil
  }

  static let firefoxBundleIdentifiers: Set<String> = [
    "org.mozilla.firefox",
    "org.mozilla.firefoxdeveloperedition",
    "org.mozilla.nightly",
  ]

  static let zenBundleIdentifiers: Set<String> = [
    "app.zen-browser.zen",
  ]

  static var supportedBundleIdentifiers: Set<String> {
    firefoxBundleIdentifiers.union(zenBundleIdentifiers)
  }

  private static func isValidID(_ id: String) -> Bool {
    let pattern = #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#
    return id.range(of: pattern, options: .regularExpression) != nil
  }
}

struct BrowserShortcutCheatSheetSection: Identifiable, Hashable {
  let group: BrowserShortcutCheatSheetGroup
  let records: [BrowserShortcutRecord]

  var id: String { group.id }
}
