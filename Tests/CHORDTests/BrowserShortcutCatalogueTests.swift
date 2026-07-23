import XCTest
@testable import Chord

final class BrowserShortcutCatalogueTests: XCTestCase {
  func testCatalogueLoadsAndPassesValidation() throws {
    let catalogue = try BrowserShortcutCatalogue.load()
    XCTAssertEqual(catalogue.platform, "macOS")
    XCTAssertFalse(catalogue.records.isEmpty)
    XCTAssertEqual(BrowserShortcutCatalogue.validate(catalogue), [])
  }

  func testNoDuplicateIDsOrTriples() throws {
    let catalogue = try BrowserShortcutCatalogue.load()
    let ids = catalogue.records.map(\.id)
    XCTAssertEqual(ids.count, Set(ids).count)

    let triples = catalogue.records.map { "\($0.browser.rawValue)|\($0.keys)|\($0.action)" }
    XCTAssertEqual(triples.count, Set(triples).count)
  }

  func testKeepRules() throws {
    let catalogue = try BrowserShortcutCatalogue.load()
    let kept = catalogue.records.filter(\.keep)

    XCTAssertGreaterThanOrEqual(kept.count, 12)
    XCTAssertLessThanOrEqual(kept.count, 20)

    for record in kept {
      XCTAssertEqual(record.availability, .default, record.id)
      XCTAssertFalse(record.sourceUrl.isEmpty, record.id)
      XCTAssertFalse((record.keepReason ?? "").isEmpty, record.id)
    }
  }

  func testCheatSheetContainsOnlyKeepDefaultRecords() throws {
    let catalogue = try BrowserShortcutCatalogue.load()
    let sections = BrowserShortcutCatalogue.cheatSheet(from: catalogue)
    let sheetRecords = sections.flatMap(\.records)

    XCTAssertFalse(sheetRecords.isEmpty)
    XCTAssertTrue(sheetRecords.allSatisfy { $0.keep && $0.availability == .default })
    XCTAssertFalse(sheetRecords.contains { $0.availability == .conflict || $0.availability == .unverified })

    let keepIDs = Set(catalogue.records.filter(\.keep).map(\.id))
    XCTAssertEqual(Set(sheetRecords.map(\.id)), keepIDs)
  }

  func testCheatSheetHasCoreGroupsAndZenSection() throws {
    let catalogue = try BrowserShortcutCatalogue.load()
    let groups = Set(BrowserShortcutCatalogue.cheatSheet(from: catalogue).map(\.group))

    XCTAssertTrue(groups.contains(.everydayBrowsing))
    XCTAssertTrue(groups.contains(.tabsAndWindows))
    XCTAssertTrue(groups.contains(.findAndNavigation))
    XCTAssertTrue(groups.contains(.developerTools))
    XCTAssertTrue(groups.contains(.zenOnly))
  }

  func testConflictAndUnverifiedExcludedEvenIfKeepWereTrue() throws {
    let conflict = BrowserShortcutRecord(
      id: "fake-conflict",
      action: "Conflicted",
      category: .page,
      browser: .zen,
      keys: "⌘S",
      availability: .conflict,
      sourceUrl: "https://example.com",
      sourceCheckedAt: "2026-07-23",
      notes: "",
      keep: true,
      keepReason: "should still be excluded"
    )
    let unverified = BrowserShortcutRecord(
      id: "fake-unverified",
      action: "Unverified",
      category: .tabs,
      browser: .firefox,
      keys: "⌘X",
      availability: .unverified,
      sourceUrl: "https://example.com",
      sourceCheckedAt: "2026-07-23",
      notes: "",
      keep: true,
      keepReason: "should still be excluded"
    )
    let catalogue = BrowserShortcutCatalogueFile(
      version: "test",
      platform: "macOS",
      browsersChecked: .init(firefox: "0", zen: "0"),
      sourceCheckedAt: "2026-07-23",
      records: [conflict, unverified]
    )

    // Direct cheat-sheet filter should drop both regardless of keep.
    let sections = BrowserShortcutCatalogue.cheatSheet(from: catalogue)
    XCTAssertTrue(sections.isEmpty)
  }

  func testMenuBindingsFilterByBrowserFamily() throws {
    let zen = BrowserShortcutCatalogue.menuBindings(
      forBundleIdentifier: "app.zen-browser.zen"
    )
    let firefox = BrowserShortcutCatalogue.menuBindings(
      forBundleIdentifier: "org.mozilla.firefox"
    )
    let safari = BrowserShortcutCatalogue.menuBindings(
      forBundleIdentifier: "com.apple.Safari"
    )

    XCTAssertFalse(zen.isEmpty)
    XCTAssertFalse(firefox.isEmpty)
    XCTAssertTrue(safari.isEmpty)
    XCTAssertGreaterThan(zen.count, firefox.count)
    XCTAssertTrue(zen.contains { $0.label == "Forward Workspace" })
    XCTAssertFalse(firefox.contains { $0.label == "Forward Workspace" })
    XCTAssertTrue(zen.contains { $0.label == "New Tab" })
    XCTAssertTrue(firefox.contains { $0.label == "New Tab" })
  }

  func testBundleIdentifierDetection() {
    XCTAssertTrue(BrowserShortcutCatalogue.applies(toBundleIdentifier: "org.mozilla.firefox"))
    XCTAssertTrue(BrowserShortcutCatalogue.applies(toBundleIdentifier: "app.zen-browser.zen"))
    XCTAssertFalse(BrowserShortcutCatalogue.applies(toBundleIdentifier: "com.apple.Safari"))
    XCTAssertEqual(
      BrowserShortcutCatalogue.browserFamily(forBundleIdentifier: "app.zen-browser.zen"),
      .zen
    )
    XCTAssertEqual(
      BrowserShortcutCatalogue.browserFamily(forBundleIdentifier: "org.mozilla.firefox"),
      .firefox
    )
  }
}
