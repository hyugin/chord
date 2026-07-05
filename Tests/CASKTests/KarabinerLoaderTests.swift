import XCTest
@testable import CASK

final class KarabinerLoaderTests: XCTestCase {
  func testRejectsOversizedConfig() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    defer {
      try? FileManager.default.removeItem(at: directory)
    }

    let configURL = directory.appendingPathComponent("karabiner.json")
    let oversized = Data(count: KarabinerLoader.maxConfigSize + 1)
    try oversized.write(to: configURL)

    let loader = KarabinerLoader(configURL: configURL)

    XCTAssertThrowsError(try loader.load()) { error in
      guard case KarabinerLoaderError.configTooLarge = error else {
        return XCTFail("Expected configTooLarge, got \(error)")
      }
    }
  }
}
