import SwiftUI

struct KeyboardMapLegendView: View {
  var body: some View {
    HStack(spacing: 16) {
      legendItem(color: Color.accentColor.opacity(0.35), label: "Occupied")
      legendItem(color: Color.green.opacity(0.2), label: "Available in config")
      legendItem(color: Color.purple.opacity(0.35), label: "Layer activator")
      legendItem(color: Color.orange.opacity(0.3), label: "Ambiguous")
    }
    .font(.caption2)
    .padding(.top, 4)
  }

  private func legendItem(color: Color, label: String) -> some View {
    HStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 2)
        .fill(color)
        .frame(width: 12, height: 12)
        .overlay {
          RoundedRectangle(cornerRadius: 2)
            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5)
        }
      Text(label)
        .foregroundStyle(.secondary)
    }
  }
}
