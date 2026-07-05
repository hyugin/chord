import SwiftUI

struct BindingRowView: View {
  let binding: Binding
  var keyColumnWidth: CGFloat = 108

  private var displayLabel: String {
    BindingLabelFormatter.displayLabel(label: binding.label, keys: binding.keys)
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 10) {
      Text(binding.keys)
        .font(.system(.callout, design: .monospaced).weight(.medium))
        .foregroundStyle(.primary)
        .frame(width: keyColumnWidth, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

      Text(displayLabel)
        .font(.callout)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .help(binding.label)
  }
}
