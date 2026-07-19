import XCTest
@testable import Chord

final class ZenShortcutCatalogTests: XCTestCase {
  func testReturnsNotionTabLockWhenZenIsFrontmost() {
    let bindings = ZenShortcutCatalog.bindings(for: "app.zen-browser.zen")

    XCTAssertEqual(bindings.count, 1)
    XCTAssertEqual(bindings[0].keys, "⌘⇧\u{2009}L")
    XCTAssertEqual(bindings[0].label, "Notion | Toggle tab lock (launcher)")
    XCTAssertEqual(bindings[0].scope, .app(bundleIdentifier: ZenShortcutCatalog.bundleIdentifier))
  }

  func testDisplayLabelIsScannable() {
    let bindings = ZenShortcutCatalog.bindings(for: ZenShortcutCatalog.bundleIdentifier)
    let binding = try XCTUnwrap(bindings.first)

    XCTAssertEqual(
      BindingLabelFormatter.displayLabel(label: binding.label, keys: binding.keys),
      "Toggle tab lock (launcher)"
    )
  }

  func testReturnsNothingForOtherApps() {
    XCTAssertTrue(ZenShortcutCatalog.bindings(for: "com.apple.Safari").isEmpty)
    XCTAssertTrue(ZenShortcutCatalog.bindings(for: "notion.id.NotionMac").isEmpty)
    XCTAssertTrue(ZenShortcutCatalog.bindings(for: nil).isEmpty)
  }
}
