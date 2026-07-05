import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var config: KarabinerConfig?
  @Published private(set) var loadError: String?
  @Published private(set) var appBindings: [Binding] = []
  @Published private(set) var globalBindings: [Binding] = []
  @Published private(set) var shortcutExtraction: ShortcutExtractionResult?
  @Published private(set) var shortcutExtractionWarnings: [String] = []

  private let loader: KarabinerLoader
  private let watcher: KarabinerConfigWatcher
  private var cancellables = Set<AnyCancellable>()

  init(loader: KarabinerLoader = KarabinerLoader(), monitor: FrontmostAppMonitor) {
    self.loader = loader
    self.watcher = KarabinerConfigWatcher(configURL: loader.configURL)

    monitor.$frontmostBundleIdentifier
      .combineLatest($config)
      .sink { [weak self] bundleIdentifier, config in
        self?.refreshBindings(bundleIdentifier: bundleIdentifier, config: config)
      }
      .store(in: &cancellables)

    watcher.onChange = { [weak self] in
      self?.reloadConfig()
    }

    reloadConfig()
    watcher.start()
  }

  func reloadConfig() {
    do {
      let loadedConfig = try loader.load()
      config = loadedConfig
      loadError = nil

      let extraction = KarabinerShortcutExtractor.extract(from: loadedConfig)
      shortcutExtraction = extraction
      shortcutExtractionWarnings = extraction.warnings
    } catch {
      config = nil
      loadError = error.localizedDescription
      appBindings = []
      globalBindings = []
      shortcutExtraction = nil
      shortcutExtractionWarnings = []
    }
  }

  func keyboardMap(for filter: KeyboardMapFilter) -> KeyboardMap? {
    guard let extraction = shortcutExtraction else { return nil }
    let profileName = config?.selectedProfile?.name ?? "Unknown"
    return KeyboardMapBuilder.build(
      from: extraction,
      profileName: profileName,
      filter: filter
    )
  }

  private func refreshBindings(bundleIdentifier: String?, config: KarabinerConfig?) {
    guard let config else {
      appBindings = []
      globalBindings = []
      return
    }

    let bindings = BindingMatcher.bindings(for: bundleIdentifier, in: config)
    appBindings = bindings.filter {
      if case .app = $0.scope { return true }
      return false
    }
    globalBindings = bindings.filter {
      if case .global = $0.scope { return true }
      return false
    }
  }
}
