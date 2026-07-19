import XCTest
@testable import Chord

final class SupplementalBindingsTests: XCTestCase {
  func testLoadsFixtureAndMatchesZen() throws {
    let fixtureURL = try XCTUnwrap(
      Bundle.module.url(forResource: "bindings", withExtension: "json", subdirectory: "Fixtures")
    )
    let entries = try SupplementalBindingsLoader(configURL: fixtureURL).load()
    let bindings = SupplementalBindingMatcher.bindings(
      for: "app.zen-browser.zen",
      from: entries
    )

    XCTAssertEqual(entries.count, 2)
    XCTAssertEqual(bindings.count, 2)
    XCTAssertTrue(bindings.contains {
      $0.keys == "⌘⇧\u{2009}L"
        && $0.label == "Notion | Toggle tab lock (launcher)"
        && $0.scope == .app(bundleIdentifier: "app.zen-browser.zen")
    })
    XCTAssertTrue(bindings.contains {
      $0.keys == "⌘⇧\u{2009}G"
        && $0.label == "Global supplemental example"
        && $0.scope == .global
    })
  }

  func testAppScopedEntryHiddenForOtherApps() throws {
    let entries = [
      SupplementalBindingEntry(
        keys: "⌘⇧L",
        label: "Notion | Toggle tab lock (launcher)",
        bundleIdentifier: "app.zen-browser.zen"
      ),
      SupplementalBindingEntry(
        keys: "⌘⇧G",
        label: "Global supplemental example",
        bundleIdentifier: nil
      ),
    ]

    let safariBindings = SupplementalBindingMatcher.bindings(
      for: "com.apple.Safari",
      from: entries
    )

    XCTAssertEqual(safariBindings.count, 1)
    XCTAssertEqual(safariBindings[0].label, "Global supplemental example")
  }

  func testDisplayLabelIsScannable() {
    let binding = Binding(
      label: "Notion | Toggle tab lock (launcher)",
      keys: "⌘⇧\u{2009}L",
      scope: .app(bundleIdentifier: "app.zen-browser.zen")
    )

    XCTAssertEqual(
      BindingLabelFormatter.displayLabel(label: binding.label, keys: binding.keys),
      "Toggle tab lock (launcher)"
    )
  }

  func testMissingFileReturnsEmptyList() throws {
    let missing = FileManager.default.temporaryDirectory
      .appendingPathComponent("chord-missing-\(UUID().uuidString).json")
    let entries = try SupplementalBindingsLoader(configURL: missing).load()
    XCTAssertTrue(entries.isEmpty)
  }

  func testRejectsOversizedConfig() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let configURL = directory.appendingPathComponent("bindings.json")
    try Data(count: SupplementalBindingsLoader.maxConfigSize + 1).write(to: configURL)

    XCTAssertThrowsError(try SupplementalBindingsLoader(configURL: configURL).load()) { error in
      guard case SupplementalBindingsLoaderError.configTooLarge = error else {
        return XCTFail("Expected configTooLarge, got \(error)")
      }
    }
  }

  func testNormalizeKeysInsertsThinSpace() {
    XCTAssertEqual(
      SupplementalBindingMatcher.normalizeKeys("⌘⇧L"),
      "⌘⇧\u{2009}L"
    )
    XCTAssertEqual(
      SupplementalBindingMatcher.normalizeKeys("⌘⇧\u{2009}L"),
      "⌘⇧\u{2009}L"
    )
  }
}
