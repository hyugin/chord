import AppKit
import Foundation

enum DownloadsUpdateInstallerError: LocalizedError {
  case downloadsUnavailable
  case noDMGFound
  case checksumFailed(URL)
  case chordAppMissingInDMG(URL)
  case commandFailed(String, Int32, String)

  var errorDescription: String? {
    switch self {
    case .downloadsUnavailable:
      return "Could not locate your Downloads folder."
    case .noDMGFound:
      return "No Chord DMG found in Downloads. Expected a file named chord.dmg or chord-<version>.dmg."
    case .checksumFailed(let url):
      return "Checksum verification failed for \(url.lastPathComponent)."
    case .chordAppMissingInDMG(let url):
      return "\(url.lastPathComponent) does not contain Chord.app."
    case .commandFailed(let command, let status, let output):
      let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
      if detail.isEmpty {
        return "\(command) failed (exit \(status))."
      }
      return "\(command) failed (exit \(status)): \(detail)"
    }
  }
}

/// Finds a Chord release DMG in Downloads, installs it into /Applications, clears
/// Gatekeeper quarantine, and relaunches — so private ad-hoc builds can update
/// without System Settings → Open Anyway.
enum DownloadsUpdateInstaller {
  static let destinationAppURL = URL(fileURLWithPath: "/Applications/Chord.app")

  static var downloadsDirectoryURL: URL? {
    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
  }

  static func isChordDMG(fileName: String) -> Bool {
    let name = fileName.lowercased()
    guard name.hasSuffix(".dmg") else { return false }
    return name == "chord.dmg" || name.hasPrefix("chord-")
  }

  static func findNewestDMG(
    in directory: URL,
    fileManager: FileManager = .default
  ) throws -> URL {
    let urls = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
      options: [.skipsHiddenFiles]
    )

    var newest: (url: URL, date: Date)?
    for url in urls {
      guard isChordDMG(fileName: url.lastPathComponent) else { continue }
      let values = try url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
      guard values.isRegularFile == true else { continue }
      let date = values.contentModificationDate ?? .distantPast
      if let current = newest {
        if date > current.date {
          newest = (url, date)
        }
      } else {
        newest = (url, date)
      }
    }

    guard let newest else {
      throw DownloadsUpdateInstallerError.noDMGFound
    }
    return newest.url
  }

  @MainActor
  static func installFromDownloadsInteractively() async {
    do {
      guard let downloads = downloadsDirectoryURL else {
        throw DownloadsUpdateInstallerError.downloadsUnavailable
      }

      let dmg = try findNewestDMG(in: downloads)
      guard confirmInstall(of: dmg) else { return }

      try await Task.detached(priority: .userInitiated) {
        try install(dmg: dmg, destination: destinationAppURL)
      }.value

      NSApplication.shared.terminate(nil)
    } catch {
      presentError(error)
    }
  }

  /// Mounts the DMG, stages Chord.app, verifies optional checksum, then hands off
  /// to a short shell script that replaces /Applications/Chord.app after this
  /// process exits and relaunches.
  static func install(dmg: URL, destination: URL) throws {
    let fileManager = FileManager.default
    try verifyChecksumIfPresent(for: dmg)

    let mountPoint = fileManager.temporaryDirectory
      .appendingPathComponent("chord-dmg-\(UUID().uuidString)", isDirectory: true)
    let stagedApp = fileManager.temporaryDirectory
      .appendingPathComponent("Chord-update-\(UUID().uuidString).app", isDirectory: true)

    try fileManager.createDirectory(at: mountPoint, withIntermediateDirectories: true)
    defer {
      _ = try? run("/usr/bin/hdiutil", ["detach", mountPoint.path, "-quiet", "-force"])
      try? fileManager.removeItem(at: mountPoint)
    }

    try run(
      "/usr/bin/hdiutil",
      ["attach", dmg.path, "-mountpoint", mountPoint.path, "-nobrowse", "-quiet"]
    )

    let bundledApp = mountPoint.appendingPathComponent("Chord.app")
    guard fileManager.fileExists(atPath: bundledApp.path) else {
      throw DownloadsUpdateInstallerError.chordAppMissingInDMG(dmg)
    }

    if fileManager.fileExists(atPath: stagedApp.path) {
      try fileManager.removeItem(at: stagedApp)
    }
    try fileManager.copyItem(at: bundledApp, to: stagedApp)
    try run("/usr/bin/xattr", ["-cr", stagedApp.path])

    try startRelaunchHelper(stagedApp: stagedApp, destination: destination)
  }

  private static func verifyChecksumIfPresent(for dmg: URL) throws {
    let checksumURL = URL(fileURLWithPath: dmg.path + ".sha256")
    guard FileManager.default.fileExists(atPath: checksumURL.path) else { return }

    do {
      try run(
        "/usr/bin/shasum",
        ["-a", "256", "-c", checksumURL.lastPathComponent],
        currentDirectory: dmg.deletingLastPathComponent()
      )
    } catch {
      throw DownloadsUpdateInstallerError.checksumFailed(dmg)
    }
  }

  private static func startRelaunchHelper(stagedApp: URL, destination: URL) throws {
    let pid = ProcessInfo.processInfo.processIdentifier
    let scriptURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("chord-relaunch-\(UUID().uuidString).sh")

    let script = """
    #!/bin/bash
    set -euo pipefail
    while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done
    rm -rf \(shellEscape(destination.path))
    /usr/bin/ditto \(shellEscape(stagedApp.path)) \(shellEscape(destination.path))
    /usr/bin/xattr -cr \(shellEscape(destination.path))
    /usr/bin/open \(shellEscape(destination.path))
    rm -rf \(shellEscape(stagedApp.path))
    rm -f \(shellEscape(scriptURL.path))
    """

    try script.write(to: scriptURL, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: scriptURL.path
    )

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [scriptURL.path]
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try process.run()
  }

  private static func shellEscape(_ value: String) -> String {
    "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
  }

  @discardableResult
  private static func run(
    _ executable: String,
    _ arguments: [String],
    currentDirectory: URL? = nil
  ) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectory

    let stdout = Pipe()
    let stderr = Pipe()
    process.standardOutput = stdout
    process.standardError = stderr

    try process.run()
    process.waitUntilExit()

    let outData = stdout.fileHandleForReading.readDataToEndOfFile()
    let errData = stderr.fileHandleForReading.readDataToEndOfFile()
    let combined = String(data: outData + errData, encoding: .utf8) ?? ""

    guard process.terminationStatus == 0 else {
      let command = ([executable] + arguments).joined(separator: " ")
      throw DownloadsUpdateInstallerError.commandFailed(
        command,
        process.terminationStatus,
        combined
      )
    }
    return combined
  }

  @MainActor
  private static func confirmInstall(of dmg: URL) -> Bool {
    let alert = NSAlert()
    alert.messageText = "Install update from Downloads?"
    alert.informativeText = """
    Found \(dmg.lastPathComponent).

    Chord will install it to /Applications, clear Gatekeeper quarantine, and relaunch.
    """
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Install & Relaunch")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal() == .alertFirstButtonReturn
  }

  @MainActor
  private static func presentError(_ error: Error) {
    let alert = NSAlert()
    alert.messageText = "Could not install update"
    alert.informativeText = error.localizedDescription
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }
}
