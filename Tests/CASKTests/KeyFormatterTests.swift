import XCTest
@testable import CASK

final class KeyFormatterTests: XCTestCase {
  func testFormatsModifiersAndKeyCode() {
    let event = KarabinerConfig.FromEvent(
      keyCode: "r",
      modifiers: KarabinerConfig.Modifiers(
        mandatory: ["left_command", "left_shift"],
        optional: nil
      )
    )

    XCTAssertEqual(KeyFormatter.format(from: event), "⌘⇧\u{2009}R")
  }

  func testFormatsNamedKeyCodes() {
    let event = KarabinerConfig.FromEvent(
      keyCode: "spacebar",
      modifiers: KarabinerConfig.Modifiers(
        mandatory: ["left_command"],
        optional: nil
      )
    )

    XCTAssertEqual(KeyFormatter.format(from: event), "⌘\u{2009}Space")
  }

  func testFormatsHyperShortcut() {
    let event = KarabinerConfig.FromEvent(
      keyCode: "p",
      modifiers: KarabinerConfig.Modifiers(
        mandatory: ["left_command", "left_control", "left_option", "left_shift"],
        optional: nil
      )
    )

    XCTAssertEqual(KeyFormatter.format(from: event), "Hyper+P")
  }

  func testFormatsHyperWithExtraModifier() {
    let event = KarabinerConfig.FromEvent(
      keyCode: "left_arrow",
      modifiers: KarabinerConfig.Modifiers(
        mandatory: ["command", "control", "option", "shift", "left_command"],
        optional: nil
      )
    )

    XCTAssertEqual(KeyFormatter.format(from: event), "Hyper+⌘+←")
  }

  func testFormatsCapsLockKey() {
    let event = KarabinerConfig.FromEvent(
      keyCode: "caps_lock",
      modifiers: nil
    )

    XCTAssertEqual(KeyFormatter.format(from: event), "Caps Lock")
  }

  func testReturnsNilForEmptyEvent() {
    XCTAssertNil(KeyFormatter.format(from: nil))
    XCTAssertNil(KeyFormatter.format(from: KarabinerConfig.FromEvent(keyCode: nil, modifiers: nil)))
  }
}
