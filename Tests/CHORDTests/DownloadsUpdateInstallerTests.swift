import XCTest
@testable import Chord

final class DownloadsUpdateInstallerTests: XCTestCase {
  func testIsChordDMGAcceptsVersionedAndBareNames() {
    XCTAssertTrue(DownloadsUpdateInstaller.isChordDMG(fileName: "chord.dmg"))
    XCTAssertTrue(DownloadsUpdateInstaller.isChordDMG(fileName: "Chord.dmg"))
    XCTAssertTrue(DownloadsUpdateInstaller.isChordDMG(fileName: "chord-0.1.5.dmg"))
    XCTAssertTrue(DownloadsUpdateInstaller.isChordDMG(fileName: "chord-1.0.0.dmg"))
  }

  func testIsChordDMGRejectsUnrelatedFiles() {
    XCTAssertFalse(DownloadsUpdateInstaller.isChordDMG(fileName: "chord.txt"))
    XCTAssertFalse(DownloadsUpdateInstaller.isChordDMG(fileName: "chord.dmg.sha256"))
    XCTAssertFalse(DownloadsUpdateInstaller.isChordDMG(fileName: "firefox.dmg"))
    XCTAssertFalse(DownloadsUpdateInstaller.isChordDMG(fileName: "my-chord-backup.dmg"))
  }

  func testFindNewestDMGPicksMostRecentlyModifiedChordDMG() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("chord-dmg-test-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let older = directory.appendingPathComponent("chord-0.1.4.dmg")
    let newer = directory.appendingPathComponent("chord.dmg")
    let ignored = directory.appendingPathComponent("notes.txt")

    try Data("old".utf8).write(to: older)
    try Data("new".utf8).write(to: newer)
    try Data("nope".utf8).write(to: ignored)

    let olderDate = Date(timeIntervalSince1970: 1_000)
    let newerDate = Date(timeIntervalSince1970: 2_000)
    try FileManager.default.setAttributes([.modificationDate: olderDate], ofItemAtPath: older.path)
    try FileManager.default.setAttributes([.modificationDate: newerDate], ofItemAtPath: newer.path)

    let found = try DownloadsUpdateInstaller.findNewestDMG(in: directory)
    XCTAssertEqual(found.lastPathComponent, "chord.dmg")
  }

  func testFindNewestDMGThrowsWhenMissing() {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("chord-dmg-empty-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    XCTAssertThrowsError(try DownloadsUpdateInstaller.findNewestDMG(in: directory)) { error in
      guard case DownloadsUpdateInstallerError.noDMGFound = error else {
        return XCTFail("Expected noDMGFound, got \(error)")
      }
    }
  }
}
