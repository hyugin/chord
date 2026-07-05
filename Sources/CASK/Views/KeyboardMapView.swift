import AppKit
import SwiftUI

struct KeyboardMapView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var monitor: FrontmostAppMonitor

  @State private var filter = KeyboardMapFilter()
  @State private var selectedKeyCode: String?

  private var map: KeyboardMap? {
    appState.keyboardMap(for: filter)
  }

  var body: some View {
    HStack(spacing: 0) {
      mainColumn
      if let selectedKeyCode, let map {
        detailPanel(for: selectedKeyCode, map: map)
      }
    }
    .frame(minWidth: 900, minHeight: 520)
  }

  private var mainColumn: some View {
    VStack(alignment: .leading, spacing: 12) {
      header
      filterControls
      Divider()

      if let loadError = appState.loadError {
        emptyState(title: "Could not load config", message: loadError)
      } else if map == nil {
        emptyState(title: "No profile", message: "Select a Karabiner profile with complex modifications.")
      } else if let map {
        if map.totalShortcuts == 0 {
          emptyState(
            title: "No bindings found",
            message: "Add complex modifications to your karabiner.json to populate the keyboard map."
          )
        } else {
          keyboardArea(map: map)
          KeyboardMapLegendView()
        }
      }

      if !appState.shortcutExtractionWarnings.isEmpty {
        warningsFooter
      }
    }
    .padding()
    .frame(maxWidth: selectedKeyCode == nil ? .infinity : 620)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Keyboard Map")
        .font(.title2.weight(.semibold))
      HStack(spacing: 8) {
        if let profileName = appState.config?.selectedProfile?.name {
          Text(profileName)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Text("·")
          .foregroundStyle(.tertiary)
        Text("Available = not occupied in Karabiner config under the current filter")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
  }

  private var filterControls: some View {
    HStack(spacing: 16) {
      Picker("Layer", selection: $filter.modifierFilter) {
        ForEach(ModifierLayerFilter.allCases) { layer in
          Text(layer.rawValue).tag(layer)
        }
      }
      .pickerStyle(.menu)
      .frame(width: 140)

      Picker("Scope", selection: scopeBinding) {
        Text("All").tag(ScopeFilter.all)
        Text("Global").tag(ScopeFilter.global)
        Text("Current app").tag(ScopeFilter.currentApp(bundleIdentifier: monitor.frontmostBundleIdentifier))
      }
      .pickerStyle(.menu)
      .frame(width: 140)

      Toggle("Occupied", isOn: $filter.showOccupied)
      Toggle("Available", isOn: $filter.showAvailable)
      Toggle("Ambiguous", isOn: $filter.showAmbiguous)
    }
    .font(.caption)
  }

  private var scopeBinding: SwiftUI.Binding<ScopeFilter> {
    SwiftUI.Binding(
      get: { filter.scopeFilter },
      set: { newValue in
        if case .currentApp = newValue {
          filter.scopeFilter = .currentApp(bundleIdentifier: monitor.frontmostBundleIdentifier)
        } else {
          filter.scopeFilter = newValue
        }
      }
    )
  }

  private func keyboardArea(map: KeyboardMap) -> some View {
    ScrollView([.horizontal, .vertical]) {
      VStack(alignment: .leading, spacing: 6) {
        ForEach(Array(map.rows.enumerated()), id: \.offset) { _, row in
          HStack(spacing: 4) {
            ForEach(row) { cell in
              KeyboardKeyView(
                cell: cell,
                isSelected: selectedKeyCode == cell.key.keyCode
              ) {
                selectedKeyCode = cell.key.keyCode
              }
            }
          }
        }
      }
      .padding(.vertical, 8)
    }
  }

  private func detailPanel(for keyCode: String, map: KeyboardMap) -> some View {
    let cell = map.rows.flatMap { $0 }.first { $0.key.keyCode == keyCode }
    let shortcuts = cell?.shortcuts ?? []

    return VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(cell?.key.displayLabel ?? keyCode)
          .font(.headline)
        Spacer()
        Button {
          selectedKeyCode = nil
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
      }

      if shortcuts.isEmpty {
        Text("No bindings for this key under the current filter.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(shortcuts) { shortcut in
              shortcutDetail(shortcut)
            }
          }
        }
      }
    }
    .padding()
    .frame(width: 280)
    .background(Color(nsColor: .windowBackgroundColor))
  }

  private func shortcutDetail(_ shortcut: KarabinerShortcut) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(shortcut.displayLabel)
        .font(.subheadline.weight(.semibold))

      Text(shortcut.trigger.displayText)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)

      Text(scopeLabel(shortcut.scope))
        .font(.caption)
        .foregroundStyle(.secondary)

      if !shortcut.actions.isEmpty {
        VStack(alignment: .leading, spacing: 2) {
          Text("Actions")
            .font(.caption.weight(.semibold))
          ForEach(shortcut.actions, id: \.self) { action in
            Text(action.summary)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }

      if let note = shortcut.warningNote {
        Text(note)
          .font(.caption2)
          .foregroundStyle(.orange)
      }

      Text("Rule \(shortcut.sourceRuleIndex + 1), manipulator \(shortcut.sourceManipulatorIndex + 1)")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func scopeLabel(_ scope: ShortcutScope) -> String {
    switch scope {
    case .global:
      return "Scope: Global"
    case .appSpecific(let patterns):
      return "Scope: App-specific (\(patterns.joined(separator: ", ")))"
    case .excludedApps(let patterns):
      return "Scope: Excluded apps (\(patterns.joined(separator: ", ")))"
    case .variableLayer(let name, let description, let ifPatterns, let unlessPatterns):
      let layerName = name ?? description ?? "layer"
      if !ifPatterns.isEmpty {
        return "Scope: Variable/layer (\(layerName), apps: \(ifPatterns.joined(separator: ", ")))"
      }
      if !unlessPatterns.isEmpty {
        return "Scope: Variable/layer (\(layerName), excluded: \(unlessPatterns.joined(separator: ", ")))"
      }
      return "Scope: Variable/layer (\(layerName))"
    case .unknown(let summary):
      return "Scope: Unknown (\(summary))"
    }
  }

  private var warningsFooter: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Extraction warnings")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.orange)
      ForEach(appState.shortcutExtractionWarnings, id: \.self) { warning in
        Text(warning)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }

  private func emptyState(title: String, message: String) -> some View {
    VStack(spacing: 8) {
      Text(title)
        .font(.headline)
      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
