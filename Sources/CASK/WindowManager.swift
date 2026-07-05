import AppKit
import SwiftUI

@MainActor
final class WindowManager: ObservableObject {
  private var keyboardMapWindow: NSWindow?

  func openKeyboardMap(appState: AppState, monitor: FrontmostAppMonitor) {
    openWindow(
      existing: &keyboardMapWindow,
      title: "Keyboard Map",
      size: NSSize(width: 900, height: 520),
      minSize: NSSize(width: 900, height: 520)
    ) {
      KeyboardMapView()
        .environmentObject(appState)
        .environmentObject(monitor)
    }
  }

  private func openWindow<Content: View>(
    existing: inout NSWindow?,
    title: String,
    size: NSSize,
    minSize: NSSize,
    @ViewBuilder content: () -> Content
  ) {
    if let existing {
      existing.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = title
    window.minSize = minSize
    window.contentView = NSHostingView(rootView: content())
    window.center()
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    existing = window
  }
}
