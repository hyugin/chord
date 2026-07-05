import XCTest
@testable import CASK

final class BindingMatcherTests: XCTestCase {
  private var config: KarabinerConfig!

  override func setUpWithError() throws {
    let fixtureURL = try XCTUnwrap(
      Bundle.module.url(forResource: "karabiner", withExtension: "json", subdirectory: "Fixtures")
    )
    let data = try Data(contentsOf: fixtureURL)
    config = try JSONDecoder().decode(KarabinerConfig.self, from: data)
  }

  func testSelectedProfileUsesGlobalProfileName() {
    XCTAssertEqual(config.selectedProfile?.name, "Default profile")
  }

  func testSafariBindingsIncludeAppAndGlobal() {
    let bindings = BindingMatcher.bindings(for: "com.apple.Safari", in: config)

    XCTAssertTrue(bindings.contains { $0.label == "Global spotlight" && $0.scope == .global })
    XCTAssertTrue(bindings.contains { $0.label == "Safari reload" })
    XCTAssertTrue(bindings.contains { $0.label == "Browser apps new tab" })
    XCTAssertTrue(bindings.contains { $0.label == "⌘\u{2009}W" })
    XCTAssertFalse(bindings.contains { $0.label == "Safari reload" && $0.scope == .global })
  }

  func testNonMatchingAppExcludesAppScopedBindings() {
    let bindings = BindingMatcher.bindings(for: "com.apple.TextEdit", in: config)

    XCTAssertTrue(bindings.contains { $0.label == "Global spotlight" })
    XCTAssertTrue(bindings.contains { $0.label == "⌘\u{2009}W" })
    XCTAssertFalse(bindings.contains { $0.label == "Safari reload" })
  }

  func testUnlessConditionExcludesMatchingApp() {
    let bindings = BindingMatcher.bindings(for: "com.apple.Terminal", in: config)

    XCTAssertFalse(bindings.contains { $0.label == "⌘\u{2009}W" })
  }

  func testChromeMatchesRegexBundleIdentifier() {
    let bindings = BindingMatcher.bindings(for: "com.google.Chrome", in: config)

    XCTAssertTrue(bindings.contains { $0.label == "Browser apps new tab" })
    XCTAssertFalse(bindings.contains { $0.label == "Safari reload" })
  }

  func testAllBindingGroupsSeparatesAppsAndGlobal() {
    let groups = BindingMatcher.allBindingGroups(in: config)

    XCTAssertTrue(groups.contains { $0.id == "global" })
    XCTAssertTrue(groups.contains { $0.id == "^com\\.apple\\.Safari$" })
    XCTAssertTrue(groups.contains { $0.id == "^com\\.google\\.Chrome$" })
  }

  func testAllBindingGroupsUseFriendlyTitles() {
    let groups = BindingMatcher.allBindingGroups(in: config)

    XCTAssertEqual(
      groups.first(where: { $0.id == "^com\\.apple\\.Safari$" })?.title,
      "Safari"
    )
    XCTAssertEqual(
      groups.first(where: { $0.id == "^com\\.google\\.Chrome$" })?.title,
      "Chrome"
    )
  }

  func testRulesWithoutDescriptionUseKeyComboAsLabel() {
    let bindings = BindingMatcher.bindings(for: "com.apple.Safari", in: config)

    XCTAssertTrue(bindings.contains { $0.label == "⌘\u{2009}W" && $0.keys == "⌘\u{2009}W" })
  }
}
