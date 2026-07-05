import XCTest
@testable import CHORD

final class ShortcutAvailabilityTests: XCTestCase {
  private var extraction: ShortcutExtractionResult!

  override func setUpWithError() throws {
    let fixtureURL = try XCTUnwrap(
      Bundle.module.url(forResource: "karabiner", withExtension: "json", subdirectory: "Fixtures")
    )
    let data = try Data(contentsOf: fixtureURL)
    let config = try JSONDecoder().decode(KarabinerConfig.self, from: data)
    extraction = KarabinerShortcutExtractor.extract(from: config)
  }

  func testHyperKeyIsOccupied() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .hyper
    filter.scopeFilter = .all

    XCTAssertFalse(
      ShortcutAvailability.isAvailable(keyCode: "h", shortcuts: extraction.shortcuts, filter: filter)
    )
  }

  func testUnoccupiedHyperKeyIsAvailable() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .hyper
    filter.scopeFilter = .all

    XCTAssertTrue(
      ShortcutAvailability.isAvailable(keyCode: "z", shortcuts: extraction.shortcuts, filter: filter)
    )
  }

  func testGlobalScopeExcludesAppOnlyBindings() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .command
    filter.scopeFilter = .global

    XCTAssertTrue(
      ShortcutAvailability.isAvailable(keyCode: "r", shortcuts: extraction.shortcuts, filter: filter)
    )
  }

  func testCurrentAppScopeIncludesAppBindings() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .command
    filter.scopeFilter = .currentApp(bundleIdentifier: "com.apple.Safari")

    XCTAssertFalse(
      ShortcutAvailability.isAvailable(keyCode: "r", shortcuts: extraction.shortcuts, filter: filter)
    )
  }

  func testKeyboardMapBuilderMarksHyperOccupied() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .hyper
    filter.scopeFilter = .all

    let map = KeyboardMapBuilder.build(
      from: extraction,
      profileName: "Default profile",
      filter: filter
    )

    let hCell = map.rows.flatMap { $0 }.first { $0.key.keyCode == "h" }
    XCTAssertNotNil(hCell)
    if case .occupied = hCell?.state {
      // expected
    } else {
      XCTFail("Expected h key to be occupied under Hyper filter")
    }
  }

  func testKeyboardMapBuilderMarksAvailableKey() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .hyper
    filter.scopeFilter = .all

    let map = KeyboardMapBuilder.build(
      from: extraction,
      profileName: "Default profile",
      filter: filter
    )

    let zCell = map.rows.flatMap { $0 }.first { $0.key.keyCode == "z" }
    XCTAssertNotNil(zCell)
    if case .available = zCell?.state {
      // expected
    } else {
      XCTFail("Expected z key to be available under Hyper filter")
    }
  }

  func testKeyboardMapBuilderMarksLayerActivator() {
    var filter = KeyboardMapFilter()
    filter.modifierFilter = .none
    filter.scopeFilter = .all

    let map = KeyboardMapBuilder.build(
      from: extraction,
      profileName: "Default profile",
      filter: filter
    )

    let capsCell = map.rows.flatMap { $0 }.first { $0.key.keyCode == "caps_lock" }
    XCTAssertNotNil(capsCell)
    if case .layerActivator = capsCell?.state {
      // expected
    } else {
      XCTFail("Expected caps lock to be a layer activator")
    }
  }
}
