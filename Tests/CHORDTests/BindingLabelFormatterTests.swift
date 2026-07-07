import XCTest
@testable import Chord

final class BindingLabelFormatterTests: XCTestCase {
  func testExtractsActionAfterArrow() {
    let label = BindingLabelFormatter.displayLabel(
      label: "Hyper+E → Open ESPN in Safari",
      keys: "Hyper+E"
    )

    XCTAssertEqual(label, "Open ESPN in Safari")
  }

  func testStripsAppScopePrefix() {
    let label = BindingLabelFormatter.displayLabel(
      label: "Rectangle Pro | Hyper+← → Left Half (⌃⌥⌘←)",
      keys: "Hyper+←"
    )

    XCTAssertEqual(label, "Left Half")
  }

  func testStripsTrailingShortcutHint() {
    let label = BindingLabelFormatter.displayLabel(
      label: "Notion | Hyper+J → Next Database Page (Ctrl+Shift+J)",
      keys: "Hyper+J"
    )

    XCTAssertEqual(label, "Next Database Page")
  }

  func testSimplifiesHyperKeyBinding() {
    let label = BindingLabelFormatter.displayLabel(
      label: "Hyper Key: Caps Lock → Cmd+Ctrl+Option+Shift (⌘⌃⌥⇧)",
      keys: "Caps Lock"
    )

    XCTAssertEqual(label, "Hyper layer key")
  }

  func testFallsBackToOriginalLabel() {
    let label = BindingLabelFormatter.displayLabel(
      label: "Safari reload",
      keys: "⌘⇧ R"
    )

    XCTAssertEqual(label, "Safari reload")
  }
}
