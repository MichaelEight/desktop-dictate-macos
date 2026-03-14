import SwiftUI

/// A button style that highlights on hover with a subtle background.
struct HoverButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                          ? Color.primary.opacity(0.15)
                          : isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
            .onHover { isHovered = $0 }
    }
}

/// A destructive button style — red by default, lighter red on hover.
struct HoverDestructiveButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isHovered ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color(red: 0.85, green: 0.25, blue: 0.25))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                          ? Color.red.opacity(0.2)
                          : isHovered ? Color.red.opacity(0.1) : Color.clear)
            )
            .onHover { isHovered = $0 }
    }
}

/// A bordered button style with enhanced hover visibility.
struct HoverBorderedButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                          ? Color.accentColor.opacity(0.3)
                          : isHovered ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.15), lineWidth: 0.5)
            )
            .onHover { isHovered = $0 }
    }
}

/// A prominent button style with enhanced hover.
struct HoverProminentButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed
                          ? Color.accentColor.opacity(0.9)
                          : isHovered ? Color.accentColor.opacity(0.8) : Color.accentColor)
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { isHovered = $0 }
    }
}

extension ButtonStyle where Self == HoverButtonStyle {
    static var hover: HoverButtonStyle { HoverButtonStyle() }
}

extension ButtonStyle where Self == HoverDestructiveButtonStyle {
    static var hoverDestructive: HoverDestructiveButtonStyle { HoverDestructiveButtonStyle() }
}

extension ButtonStyle where Self == HoverBorderedButtonStyle {
    static var hoverBordered: HoverBorderedButtonStyle { HoverBorderedButtonStyle() }
}

extension ButtonStyle where Self == HoverProminentButtonStyle {
    static var hoverProminent: HoverProminentButtonStyle { HoverProminentButtonStyle() }
}

/// A tab button with hover highlight for the settings window.
struct HoverTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.15)
                          : isHovered ? Color.primary.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : isHovered ? .primary : .secondary)
        .onHover { isHovered = $0 }
    }
}

/// A segmented picker with hover effects on each segment.
struct HoverSegmentedPicker: View {
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, label in
                HoverSegment(
                    label: label,
                    isSelected: selection == index,
                    isFirst: index == 0,
                    isLast: index == options.count - 1
                ) {
                    selection = index
                }
            }
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct HoverSegment: View {
    let label: String
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isSelected
                              ? Color.accentColor.opacity(0.8)
                              : isHovered ? Color.primary.opacity(0.1) : Color.clear)
                        .padding(1.5)
                )
                .foregroundStyle(isSelected ? .white : isHovered ? .primary : .secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

/// A toggle style with hover highlight.
struct HoverToggleStyle: ToggleStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }
}
