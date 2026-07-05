import Darwin
import Foundation

final class KarabinerConfigWatcher {
  private let configURL: URL
  private var source: DispatchSourceFileSystemObject?
  private var fileDescriptor: Int32 = -1
  var onChange: (() -> Void)?

  init(configURL: URL = KarabinerLoader.defaultConfigURL) {
    self.configURL = configURL
  }

  deinit {
    stop()
  }

  func start() {
    stop()

    let path = configURL.path
    guard FileManager.default.fileExists(atPath: path) else { return }

    fileDescriptor = open(path, O_EVTONLY)
    guard fileDescriptor >= 0 else { return }

    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fileDescriptor,
      eventMask: [.write, .rename, .delete],
      queue: .main
    )

    source.setEventHandler { [weak self] in
      self?.onChange?()
    }

    source.setCancelHandler { [weak self] in
      guard let self, self.fileDescriptor >= 0 else { return }
      close(self.fileDescriptor)
      self.fileDescriptor = -1
    }

    self.source = source
    source.resume()
  }

  func stop() {
    source?.cancel()
    source = nil
  }
}
