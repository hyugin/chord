import XCTest
@testable import Chord

final class ConditionEvaluatorTests: XCTestCase {
  func testUnlessExcludesMatchingBundleIdentifier() {
    let conditions = [
      KarabinerConfig.Condition(
        type: "frontmost_application_unless",
        bundleIdentifiers: ["^com\\.apple\\.Terminal$"]
      ),
    ]

    XCTAssertTrue(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.Safari")
    )
    XCTAssertFalse(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.Terminal")
    )
  }

  func testIfRequiresMatchingBundleIdentifier() {
    let conditions = [
      KarabinerConfig.Condition(
        type: "frontmost_application_if",
        bundleIdentifiers: ["^com\\.apple\\.Safari$"]
      ),
    ]

    XCTAssertTrue(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.Safari")
    )
    XCTAssertFalse(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.TextEdit")
    )
  }

  func testCombinedIfAndUnlessConditions() {
    let conditions = [
      KarabinerConfig.Condition(
        type: "frontmost_application_if",
        bundleIdentifiers: ["^com\\.apple\\.Safari$", "^com\\.google\\.Chrome$"]
      ),
      KarabinerConfig.Condition(
        type: "frontmost_application_unless",
        bundleIdentifiers: ["^com\\.apple\\.Terminal$"]
      ),
    ]

    XCTAssertTrue(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.Safari")
    )
    XCTAssertFalse(
      ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: "com.apple.Terminal")
    )
  }

  func testUnlessWithoutBundleIdentifierIsIgnored() {
    let conditions = [
      KarabinerConfig.Condition(
        type: "frontmost_application_unless",
        bundleIdentifiers: ["^com\\.apple\\.Terminal$"]
      ),
    ]

    XCTAssertTrue(ConditionEvaluator.conditionsSatisfied(conditions, bundleIdentifier: nil))
  }
}
