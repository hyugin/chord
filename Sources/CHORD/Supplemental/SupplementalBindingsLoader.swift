import Foundation

enum SupplementalBindingsLoaderError: LocalizedError {
  case configTooLarge(URL, size: Int)
  case readFailed(URL, underlying: Error)
  case decodeFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .configTooLarge(let url, let size):
      let kilobytes = Double(size) / 1024
      return String(format: "Chord bindings at %@ are too large (%.0f KB)", url.path, kilobytes)
    case .readFailed(let url, let underlying):
      return "Failed to read \(url.path): \(underlying.localizedDescription)"
    case .decodeFailed(let underlying):
      return "Failed to parse chord bindings.json: \(underlying.localizedDescription)"
    }
  }
}

struct SupplementalBindingsLoader {
  static let defaultConfigURL: URL = {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".config/chord/bindings.json")
  }()

  static let maxConfigSize = 256 * 1024

  let configURL: URL

  init(configURL: URL = SupplementalBindingsLoader.defaultConfigURL) {
    self.configURL = configURL
  }

  func ensureConfigDirectoryExists() {
    let directory = configURL.deletingLastPathComponent()
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  }

  /// Missing file is not an error — returns an empty list.
  func load() throws -> [SupplementalBindingEntry] {
    guard FileManager.default.fileExists(atPath: configURL.path) else {
      return []
    }

    let attributes = try FileManager.default.attributesOfItem(atPath: configURL.path)
    if let size = attributes[.size] as? Int, size > Self.maxConfigSize {
      throw SupplementalBindingsLoaderError.configTooLarge(configURL, size: size)
    }

    let data: Data
    do {
      data = try Data(contentsOf: configURL)
    } catch {
      throw SupplementalBindingsLoaderError.readFailed(configURL, underlying: error)
    }

    do {
      let file = try JSONDecoder().decode(SupplementalBindingsFile.self, from: data)
      return file.bindings
    } catch {
      throw SupplementalBindingsLoaderError.decodeFailed(underlying: error)
    }
  }
}
