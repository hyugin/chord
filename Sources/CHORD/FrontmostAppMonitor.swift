import AppKit
import Combine
import Foundation

@MainActor
final class FrontmostAppMonitor: ObservableObject {
  @Published private(set) var frontmostAppName: String = "Unknown"
  @Published private(set) var frontmostBundleIdentifier: String?

  private var observer: NSObjectProtocol?
  private var lastMeaningfulApp: NSRunningApplication?
  private let ownBundleIdentifier = Bundle.main.bundleIdentifier

  init() {
    if let app = NSWorkspace.shared.frontmostApplication,
       !isOwnApp(app) {
      rememberAndUpdate(from: app)
    } else {
      updateFromLastMeaningfulApp()
    }

    observer = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didActivateApplicationNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let self,
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
              as? NSRunningApplication else {
        return
      }

      Task { @MainActor in
        self.handleActivation(of: app)
      }
    }
  }

  deinit {
    if let observer {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }

  private func handleActivation(of app: NSRunningApplication) {
    guard !isOwnApp(app) else { return }
    rememberAndUpdate(from: app)
  }

  private func rememberAndUpdate(from app: NSRunningApplication) {
    lastMeaningfulApp = app
    update(from: app)
  }

  private func updateFromLastMeaningfulApp() {
    if let lastMeaningfulApp {
      update(from: lastMeaningfulApp)
      return
    }

    let apps = NSWorkspace.shared.runningApplications

    if let app = apps.first(where: {
      $0.isActive && $0.activationPolicy == .regular && !isOwnApp($0)
    }) {
      rememberAndUpdate(from: app)
      return
    }

    if let app = apps.first(where: {
      $0.activationPolicy == .regular && !isOwnApp($0)
    }) {
      rememberAndUpdate(from: app)
    }
  }

  private func update(from app: NSRunningApplication) {
    frontmostAppName = app.localizedName ?? "Unknown"
    frontmostBundleIdentifier = app.bundleIdentifier
  }

  private func isOwnApp(_ app: NSRunningApplication) -> Bool {
    guard let ownBundleIdentifier else { return false }
    return app.bundleIdentifier == ownBundleIdentifier
  }
}
