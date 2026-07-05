import Foundation

enum KeyboardMapBuilder {
  static func build(
    from extraction: ShortcutExtractionResult,
    profileName: String,
    filter: KeyboardMapFilter
  ) -> KeyboardMap {
    let filtered = extraction.shortcuts.filter { shortcut in
      ShortcutAvailability.matchesScope(shortcut, filter: filter.scopeFilter)
        && KeyFormatter.matchesModifierFilter(shortcut.trigger, filter: filter.modifierFilter)
    }

    let rows = KeyboardLayout.usANSI.map { row in
      row.keys.map { key in
        cell(for: key, allShortcuts: extraction.shortcuts, filtered: filtered, filter: filter)
      }
    }

    return KeyboardMap(
      profileName: profileName,
      rows: rows,
      warnings: extraction.warnings,
      totalShortcuts: extraction.shortcuts.count
    )
  }

  private static func cell(
    for key: KeyboardKey,
    allShortcuts: [KarabinerShortcut],
    filtered: [KarabinerShortcut],
    filter: KeyboardMapFilter
  ) -> KeyboardMapCell {
    let keyMatches = filtered.filter {
      $0.trigger.keyCode?.lowercased() == key.keyCode.lowercased()
    }

    let layerActivators = keyMatches.filter(\.trigger.isLayerActivator)
    if !layerActivators.isEmpty {
      return KeyboardMapCell(
        id: key.keyCode,
        key: key,
        state: filter.showOccupied ? .layerActivator : .hidden,
        shortcuts: layerActivators
      )
    }

    let ambiguous = keyMatches.filter { $0.warningNote != nil || !$0.supported }
    if !ambiguous.isEmpty, filter.showAmbiguous {
      let warning = ambiguous.compactMap(\.warningNote).joined(separator: "; ")
      return KeyboardMapCell(
        id: key.keyCode,
        key: key,
        state: .ambiguous(warning: warning.isEmpty ? "Partially supported binding" : warning),
        shortcuts: keyMatches
      )
    }

    if !keyMatches.isEmpty {
      if filter.showOccupied {
        return KeyboardMapCell(
          id: key.keyCode,
          key: key,
          state: .occupied(count: keyMatches.count),
          shortcuts: keyMatches
        )
      }
      return KeyboardMapCell(
        id: key.keyCode,
        key: key,
        state: .hidden,
        shortcuts: keyMatches
      )
    }

    let available = ShortcutAvailability.isAvailable(
      keyCode: key.keyCode,
      shortcuts: allShortcuts,
      filter: filter
    )

    if available, filter.showAvailable, isMappableKey(key.keyCode) {
      return KeyboardMapCell(
        id: key.keyCode,
        key: key,
        state: .available,
        shortcuts: []
      )
    }

    return KeyboardMapCell(
      id: key.keyCode,
      key: key,
      state: .hidden,
      shortcuts: []
    )
  }

  private static func isMappableKey(_ keyCode: String) -> Bool {
    !["left_control", "left_option", "left_command", "right_command", "right_option", "shift", "right_shift"].contains(keyCode)
  }
}
