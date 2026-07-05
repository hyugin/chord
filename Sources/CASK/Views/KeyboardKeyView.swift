import SwiftUI

struct KeyboardKeyView: View {
  let cell: KeyboardMapCell
  let isSelected: Bool
  let onSelect: () -> Void

  private let baseWidth: CGFloat = 36

  var body: some View {
    Group {
      switch cell.state {
      case .hidden:
        keyButton.opacity(0.25)
      default:
        keyButton
      }
    }
  }

  private var keyButton: some View {
    Button(action: onSelect) {
      VStack(spacing: 2) {
        Text(cell.key.displayLabel)
          .font(.system(size: 10, weight: .medium))
          .lineLimit(1)
          .minimumScaleFactor(0.7)

        if case .occupied(let count) = cell.state, count > 1 {
          Text("\(count)")
            .font(.system(size: 8, weight: .bold))
        }
      }
      .frame(width: baseWidth * cell.key.width, height: 36)
      .background(backgroundColor)
      .foregroundStyle(foregroundColor)
      .clipShape(RoundedRectangle(cornerRadius: 4))
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
      }
    }
    .buttonStyle(.plain)
    .disabled(cell.state == .hidden)
  }

  private var backgroundColor: Color {
    switch cell.state {
    case .layerActivator:
      return Color.purple.opacity(0.35)
    case .occupied:
      return Color.accentColor.opacity(0.35)
    case .available:
      return Color.green.opacity(0.2)
    case .ambiguous:
      return Color.orange.opacity(0.3)
    case .hidden:
      return Color.secondary.opacity(0.08)
    }
  }

  private var foregroundColor: Color {
    switch cell.state {
    case .available:
      return .primary.opacity(0.7)
    case .hidden:
      return .secondary.opacity(0.5)
    default:
      return .primary
    }
  }

  private var borderColor: Color {
    if isSelected {
      return .accentColor
    }
    switch cell.state {
    case .available:
      return Color.green.opacity(0.5)
    case .ambiguous:
      return Color.orange.opacity(0.6)
    case .layerActivator:
      return Color.purple.opacity(0.6)
    default:
      return Color.secondary.opacity(0.3)
    }
  }
}
