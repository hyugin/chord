import XCTest
@testable import Chord

final class RegexMatcherTests: XCTestCase {
  func testMatchesValidRegexPattern() {
    XCTAssertTrue(RegexMatcher.matches(pattern: "^com\\.apple\\.Safari$", in: "com.apple.Safari"))
    XCTAssertFalse(RegexMatcher.matches(pattern: "^com\\.apple\\.Safari$", in: "com.apple.TextEdit"))
  }

  func testFallsBackToExactMatchForInvalidPattern() {
    XCTAssertTrue(RegexMatcher.matches(pattern: "com.apple.Safari", in: "com.apple.Safari"))
    XCTAssertFalse(RegexMatcher.matches(pattern: "[invalid", in: "com.apple.Safari"))
  }

  func testRejectsOverlyLongPatterns() {
    let longPattern = String(repeating: "a", count: RegexMatcher.maxPatternLength + 1)
    XCTAssertFalse(RegexMatcher.matches(pattern: longPattern, in: "a"))
  }

  func testTimesOutOnCatastrophicBacktracking() {
    let pathologicalPattern = "(a+)+$"
    let input = String(repeating: "a", count: 30) + "X"

    XCTAssertFalse(RegexMatcher.matches(pattern: pathologicalPattern, in: input))
  }
}
