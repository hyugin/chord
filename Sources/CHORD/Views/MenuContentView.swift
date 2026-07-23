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
      }

      if let supplementalLoadError = appState.supplementalLoadError {
        Text(supplementalLoadError)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      bindingsSection

      Divider()

      VStack(alignment: .leading, spacing: 2) {
        MenuActionRow(title: "Open Keyboard Map…") {
          windowManager.openKeyboardMap(appState: appState, monitor: monitor)
        }

        MenuActionRow(title: "Check for Updates…") {
          Task {
            await DownloadsUpdateInstaller.installFromDownloadsInteractively()
          }
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
      HStack(alignment: .firstTextBaseline) {
        Text("Chord")
          .font(.headline)
        Spacer(minLength: 8)
        Text("v\(AppVersion.marketing)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Text(monitor.frontmostAppName)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var bindingsSection: some View {
    let appSectionBindings = appState.appBindings + appState.browserBindings
    let hasAppSection = !appSectionBindings.isEmpty
    let hasGlobal = !appState.globalBindings.isEmpty

    if !hasAppSection && !hasGlobal {
      Text("No custom bindings for \(monitor.frontmostAppName)")
        .font(.caption)
        .foregroundStyle(.secondary)
    } else {
      if hasAppSection {
        section(title: monitor.frontmostAppName, bindings: appSectionBindings)
      }

      if hasGlobal {
        if hasAppSection {
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
