import SwiftUI

struct BrowserShortcutCheatSheetView: View {
  let catalogue: BrowserShortcutCatalogueFile
  let sections: [BrowserShortcutCheatSheetSection]

  init(catalogue: BrowserShortcutCatalogueFile) {
    self.catalogue = catalogue
    self.sections = BrowserShortcutCatalogue.cheatSheet(from: catalogue)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        header
        compatibility
        ForEach(sections) { section in
          sectionView(section)
        }
        appendix
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(minWidth: 460, minHeight: 420)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Firefox / Zen Shortcuts")
        .font(.title2.weight(.semibold))
      Text("Trimmed cheat sheet derived from catalogue \(catalogue.version)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private var compatibility: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Compatibility")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(
        "macOS · Firefox \(catalogue.browsersChecked.firefox) · Zen \(catalogue.browsersChecked.zen) · checked \(catalogue.sourceCheckedAt). Custom remaps and extensions may change behavior."
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
  }

  private func sectionView(_ section: BrowserShortcutCheatSheetSection) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(section.group.rawValue)
        .font(.headline)

      ForEach(section.records) { record in
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text(record.keys)
            .font(.system(.body, design: .monospaced).weight(.medium))
            .frame(width: 100, alignment: .leading)
          VStack(alignment: .leading, spacing: 2) {
            Text(record.action)
              .font(.body)
            if !record.notes.isEmpty, record.browser != .both {
              Text(record.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          Spacer(minLength: 0)
        }
      }
    }
  }

  private var appendix: some View {
    DisclosureGroup("Full catalogue (\(catalogue.records.count) records)") {
      VStack(alignment: .leading, spacing: 6) {
        ForEach(catalogue.records) { record in
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(record.keys)
              .font(.system(.caption, design: .monospaced))
              .frame(width: 88, alignment: .leading)
            Text(record.action)
              .font(.caption)
            Text("· \(record.browser.rawValue)")
              .font(.caption2)
              .foregroundStyle(.secondary)
            if record.keep {
              Text("keep")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green)
            }
            if record.availability != .default {
              Text(record.availability.rawValue)
                .font(.caption2)
                .foregroundStyle(.orange)
            }
            Spacer(minLength: 0)
          }
        }
      }
      .padding(.top, 6)
    }
    .font(.subheadline)
  }
}
