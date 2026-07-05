import AppKit
import SwiftUI

@main
struct CASKApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var monitor: FrontmostAppMonitor
  @StateObject private var appState: AppState
  @StateObject private var windowManager = WindowManager()

  init() {
    let monitor = FrontmostAppMonitor()
    _monitor = StateObject(wrappedValue: monitor)
    _appState = StateObject(wrappedValue: AppState(monitor: monitor))
  }

  var body: some Scene {
    MenuBarExtra {
      MenuContentView()
        .environmentObject(appState)
        .environmentObject(monitor)
        .environmentObject(windowManager)
    } label: {
      Image(nsImage: MenuBarIcon.makeImage())
    }
    .menuBarExtraStyle(.window)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
       let icon = NSImage(contentsOf: url) {
      NSApp.applicationIconImage = icon
    }
  }
}
