import SwiftUI

/// A question-mark icon that shows a tooltip popover on hover with minimal delay.
struct QuickTooltip: View {
    let text: String
    @State private var isShowing = false
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        Image(systemName: "questionmark.circle")
            .foregroundStyle(.secondary)
            .onHover { hovering in
                hoverTask?.cancel()
                if hovering {
                    hoverTask = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        guard !Task.isCancelled else { return }
                        isShowing = true
                    }
                } else {
                    isShowing = false
                }
            }
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                Text(text)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: 220)
                    .fixedSize(horizontal: false, vertical: true)
            }
    }
}
