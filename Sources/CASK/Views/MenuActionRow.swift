import SwiftUI

struct MenuActionRow: View {
  let title: String
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.callout)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
          RoundedRectangle(cornerRadius: 4)
            .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
  }
}
