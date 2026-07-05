import Foundation

enum KarabinerLoaderError: LocalizedError {
  case configNotFound(URL)
  case configTooLarge(URL, size: Int)
  case readFailed(URL, underlying: Error)
  case decodeFailed(underlying: Error)

  var errorDescription: String? {
    switch self {
    case .configNotFound(let url):
      return "Karabiner config not found at \(url.path)"
    case .configTooLarge(let url, let size):
      let megabytes = Double(size) / (1024 * 1024)
      return String(format: "Karabiner config at %@ is too large (%.1f MB)", url.path, megabytes)
    case .readFailed(let url, let underlying):
      return "Failed to read \(url.path): \(underlying.localizedDescription)"
    case .decodeFailed(let underlying):
      return "Failed to parse karabiner.json: \(underlying.localizedDescription)"
    }
  }
}

struct KarabinerLoader {
  static let defaultConfigURL: URL = {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".config/karabiner/karabiner.json")
  }()

  static let maxConfigSize = 10 * 1024 * 1024

  let configURL: URL

  init(configURL: URL = KarabinerLoader.defaultConfigURL) {
    self.configURL = configURL
  }

  func load() throws -> KarabinerConfig {
    guard FileManager.default.fileExists(atPath: configURL.path) else {
      throw KarabinerLoaderError.configNotFound(configURL)
    }

    let attributes = try FileManager.default.attributesOfItem(atPath: configURL.path)
    if let size = attributes[.size] as? Int, size > Self.maxConfigSize {
      throw KarabinerLoaderError.configTooLarge(configURL, size: size)
    }

    let data: Data
    do {
      data = try Data(contentsOf: configURL)
    } catch {
      throw KarabinerLoaderError.readFailed(configURL, underlying: error)
    }

    do {
      let decoder = JSONDecoder()
      return try decoder.decode(KarabinerConfig.self, from: data)
    } catch {
      throw KarabinerLoaderError.decodeFailed(underlying: error)
    }
  }
}
