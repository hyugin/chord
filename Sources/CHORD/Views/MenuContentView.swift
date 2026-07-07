import SwiftUI

struct MenuContentView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var monitor: FrontmostAppMonitor
  @EnvironmentObject private var windowManager: WindowManager

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header

      if let loadError = appState.loadError {
        Text(loadError)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      } else {
        bindingsSection
      }

      Divider()

      VStack(alignment: .leading, spacing: 2) {
        MenuActionRow(title: "Open Keyboard Map…") {
          windowManager.openKeyboardMap(appState: appState, monitor: monitor)
        }

        MenuActionRow(title: "Quit Chord") {
          NSApplication.shared.terminate(nil)
        }
      }
    }
    .padding(12)
    .frame(width: 380)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("Chord")
        .font(.headline)
      Text(monitor.frontmostAppName)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var bindingsSection: some View {
    if appState.appBindings.isEmpty && appState.globalBindings.isEmpty {
      Text("No custom bindings for \(monitor.frontmostAppName)")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      if !appState.appBindings.isEmpty {
        section(title: monitor.frontmostAppName, bindings: appState.appBindings)
      }

      if !appState.globalBindings.isEmpty {
        if !appState.appBindings.isEmpty {
          Divider()
        }
        section(title: "Global", bindings: appState.globalBindings)
      }
    }
  }

  private func section(title: String, bindings: [Binding]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      ForEach(bindings) { binding in
        BindingRowView(binding: binding)
      }
    }
  }
}
