import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var config: KarabinerConfig?
  @Published private(set) var loadError: String?
  @Published private(set) var supplementalEntries: [SupplementalBindingEntry] = []
  @Published private(set) var supplementalLoadError: String?
  @Published private(set) var appBindings: [Binding] = []
  @Published private(set) var browserBindings: [Binding] = []
  @Published private(set) var globalBindings: [Binding] = []
  @Published private(set) var shortcutExtraction: ShortcutExtractionResult?
  @Published private(set) var shortcutExtractionWarnings: [String] = []

  private let loader: KarabinerLoader
  private let supplementalLoader: SupplementalBindingsLoader
  private let watcher: KarabinerConfigWatcher
  private let supplementalWatcher: KarabinerConfigWatcher
  private var cancellables = Set<AnyCancellable>()

  init(
    loader: KarabinerLoader = KarabinerLoader(),
    supplementalLoader: SupplementalBindingsLoader = SupplementalBindingsLoader(),
    monitor: FrontmostAppMonitor
  ) {
    self.loader = loader
    self.supplementalLoader = supplementalLoader
    self.watcher = KarabinerConfigWatcher(configURL: loader.configURL)
    // Watch the config directory so creating bindings.json after launch is picked up.
    self.supplementalWatcher = KarabinerConfigWatcher(
      configURL: supplementalLoader.configURL.deletingLastPathComponent()
    )

    Publishers.CombineLatest3(
      monitor.$frontmostBundleIdentifier,
      $config,
      $supplementalEntries
    )
    .sink { [weak self] bundleIdentifier, config, supplementalEntries in
      self?.refreshBindings(
        bundleIdentifier: bundleIdentifier,
        config: config,
        supplementalEntries: supplementalEntries
      )
    }
    .store(in: &cancellables)

    watcher.onChange = { [weak self] in
      self?.reloadConfig()
    }
    supplementalWatcher.onChange = { [weak self] in
      self?.reloadSupplementalBindings()
    }

    supplementalLoader.ensureConfigDirectoryExists()
    reloadConfig()
    reloadSupplementalBindings()
    watcher.start()
    supplementalWatcher.start()
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
      shortcutExtraction = nil
      shortcutExtractionWarnings = []
    }
  }

  func reloadSupplementalBindings() {
    do {
      supplementalEntries = try supplementalLoader.load()
      supplementalLoadError = nil
    } catch {
      supplementalEntries = []
      supplementalLoadError = error.localizedDescription
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

  private func refreshBindings(
    bundleIdentifier: String?,
    config: KarabinerConfig?,
    supplementalEntries: [SupplementalBindingEntry]
  ) {
    browserBindings = BrowserShortcutCatalogue.menuBindings(
      forBundleIdentifier: bundleIdentifier
    )

    let karabinerBindings = config.map { BindingMatcher.bindings(for: bundleIdentifier, in: $0) } ?? []
    let supplementalBindings = SupplementalBindingMatcher.bindings(
      for: bundleIdentifier,
      from: supplementalEntries
    )
    let bindings = karabinerBindings + supplementalBindings

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
