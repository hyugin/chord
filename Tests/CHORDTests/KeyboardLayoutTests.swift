import XCTest
@testable import CHORD

final class KeyboardLayoutTests: XCTestCase {
  func testUSANSIContainsLetterKeys() {
    let q = KeyboardLayout.key(for: "q")
    XCTAssertNotNil(q)
    XCTAssertEqual(q?.displayLabel, "Q")
  }

  func testUSANSIContainsFunctionKeys() {
    let f1 = KeyboardLayout.key(for: "f1")
    XCTAssertNotNil(f1)
    XCTAssertEqual(f1?.displayLabel, "F1")
  }

  func testUSANSIContainsSpacebar() {
    let space = KeyboardLayout.key(for: "spacebar")
    XCTAssertNotNil(space)
    XCTAssertEqual(space?.displayLabel, "Space")
  }

  func testUSANSIRowCount() {
    XCTAssertEqual(KeyboardLayout.usANSI.count, 6)
  }
}
