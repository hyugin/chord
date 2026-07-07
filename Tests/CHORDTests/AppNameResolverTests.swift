import XCTest
@testable import Chord

final class AppNameResolverTests: XCTestCase {
  func testPrettifiesCommonBundlePattern() {
    XCTAssertEqual(
      AppNameResolver.prettifyPattern("^com\\.apple\\.Safari$"),
      "Safari"
    )
    XCTAssertEqual(
      AppNameResolver.prettifyPattern("^com\\.google\\.Chrome$"),
      "Chrome"
    )
  }

  func testFallsBackToOriginalPatternWhenUnrecognized() {
    XCTAssertEqual(
      AppNameResolver.prettifyPattern("not-a-bundle-pattern"),
      "not-a-bundle-pattern"
    )
  }
}
