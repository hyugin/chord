import Foundation

/// One action in one browser context. Differing Firefox/Zen bindings stay as separate records.
struct BrowserShortcutRecord: Codable, Hashable, Identifiable {
  enum Category: String, Codable, CaseIterable {
    case window
    case tabs
    case navigation
    case search
    case page
    case developerTools = "developer-tools"
    case zenWorkspaces = "zen-workspaces"
    case zenSidebar = "zen-sidebar"
  }

  enum Browser: String, Codable, CaseIterable {
    case firefox
    case zen
    case both
  }

  enum Availability: String, Codable, CaseIterable {
    case `default`
    case versionDependent = "version-dependent"
    case conflict
    case unverified
  }

  let id: String
  let action: String
  let category: Category
  let browser: Browser
  /// macOS display string using ⌃⌥⇧⌘ order, e.g. `⇧⌘T`.
  let keys: String
  let availability: Availability
  let sourceUrl: String
  let sourceCheckedAt: String
  let notes: String
  let keep: Bool
  let keepReason: String?
}

struct BrowserShortcutCatalogueFile: Codable, Hashable {
  let version: String
  let platform: String
  let browsersChecked: BrowsersChecked
  let sourceCheckedAt: String
  let records: [BrowserShortcutRecord]

  struct BrowsersChecked: Codable, Hashable {
    let firefox: String
    let zen: String
  }
}

enum BrowserShortcutCheatSheetGroup: String, CaseIterable, Identifiable {
  case everydayBrowsing = "Everyday browsing"
  case tabsAndWindows = "Tabs and windows"
  case findAndNavigation = "Find and navigation"
  case developerTools = "Developer tools"
  case zenOnly = "Zen-only features"

  var id: String { rawValue }

  static func group(for record: BrowserShortcutRecord) -> BrowserShortcutCheatSheetGroup {
    if record.browser == .zen
      || record.category == .zenWorkspaces
      || record.category == .zenSidebar
    {
      return .zenOnly
    }

    if everydayIDs.contains(record.id) {
      return .everydayBrowsing
    }

    switch record.category {
    case .page:
      return .everydayBrowsing
    case .tabs, .window:
      return .tabsAndWindows
    case .navigation, .search:
      return .findAndNavigation
    case .developerTools:
      return .developerTools
    case .zenWorkspaces, .zenSidebar:
      return .zenOnly
    }
  }

  private static let everydayIDs: Set<String> = [
    "firefox-zen-new-tab",
    "firefox-zen-close-tab",
    "firefox-zen-focus-address",
    "firefox-zen-reload",
    "firefox-zen-find",
  ]
}
