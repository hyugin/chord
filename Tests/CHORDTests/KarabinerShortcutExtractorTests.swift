import XCTest
@testable import CHORD

final class KarabinerShortcutExtractorTests: XCTestCase {
  private var config: KarabinerConfig!

  override func setUpWithError() throws {
    let fixtureURL = try XCTUnwrap(
      Bundle.module.url(forResource: "karabiner", withExtension: "json", subdirectory: "Fixtures")
    )
    let data = try Data(contentsOf: fixtureURL)
    config = try JSONDecoder().decode(KarabinerConfig.self, from: data)
  }

  func testExtractsGlobalShortcut() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    XCTAssertTrue(result.shortcuts.contains { $0.displayLabel == "Global spotlight" })
    XCTAssertTrue(result.shortcuts.contains { $0.scope == .global })
  }

  func testExtractsAppScopedShortcut() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let safari = result.shortcuts.first { $0.sourceRuleDescription == "Safari reload" }
    XCTAssertNotNil(safari)
    if case .appSpecific(let patterns) = safari?.scope {
      XCTAssertTrue(patterns.contains("^com\\.apple\\.Safari$"))
    } else {
      XCTFail("Expected app-specific scope")
    }
  }

  func testExtractsUnlessScope() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let unless = result.shortcuts.first { $0.trigger.keyCode == "w" && $0.sourceRuleDescription == nil }
    XCTAssertNotNil(unless)
    if case .excludedApps(let patterns) = unless?.scope {
      XCTAssertTrue(patterns.contains("^com\\.apple\\.Terminal$"))
    } else {
      XCTFail("Expected excluded-apps scope")
    }
  }

  func testExtractsHyperShortcut() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let hyper = result.shortcuts.first { $0.sourceRuleDescription == "Hyper window manager" }
    XCTAssertNotNil(hyper)
    XCTAssertTrue(hyper?.trigger.isHyper == true)
    XCTAssertEqual(hyper?.trigger.displayText, "Hyper+H")
  }

  func testDetectsHyperLayerActivator() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let layer = result.shortcuts.first { $0.sourceRuleDescription == "Hyper layer key (Caps Lock)" }
    XCTAssertNotNil(layer)
    XCTAssertTrue(layer?.trigger.isLayerActivator == true)
  }

  func testExtractsVariableLayerScope() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let layered = result.shortcuts.first { $0.sourceRuleDescription == "Layer-scoped launcher" }
    XCTAssertNotNil(layered)
    if case .variableLayer(let name, _, _, _) = layered?.scope {
      XCTAssertEqual(name, "hyper")
    } else {
      XCTFail("Expected variable layer scope")
    }
  }

  func testSummarizesShellCommandAction() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    let hyper = result.shortcuts.first { $0.sourceRuleDescription == "Hyper window manager" }
    XCTAssertTrue(hyper?.actions.contains { $0.summary.contains("shell:") } == true)
  }

  func testWarnsOnSimultaneousInput() {
    let result = KarabinerShortcutExtractor.extract(from: config)
    XCTAssertTrue(result.warnings.contains { $0.contains("Simultaneous key input") })
  }
}
