import AppKit
import SwiftUI

/// A small, always-on-top floating pill that shows recording/transcribing status.
/// Visible even when the menu bar popover is closed.
final class FloatingRecordingWindow {
    private var panel: NSPanel?

    func show(state: RecordingState) {
        hide()

        let view: AnyView
        switch state {
        case .recording:
            view = AnyView(RecordingPillView(startTime: Date()))
        case .transcribing:
            view = AnyView(TranscribingPillView())
        default:
            return
        }

        showPanel(view: view)
    }

    func showSuccess() {
        hide()
        showPanel(view: AnyView(SuccessPillView()))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hide()
        }
    }

    func showError(_ message: String) {
        hide()
        showPanel(view: AnyView(ErrorPillView(message: message)))

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.hide()
        }
    }

    private func showPanel(view: AnyView) {
        let hostingView = NSHostingView(rootView: view)
        let fittingSize = hostingView.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - fittingSize.width / 2
            let y = screenFrame.maxY - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.close()
        panel = nil
    }

    /// No-op — streaming text is no longer shown in the floating pill.
    func updateStreamingText(_ text: String) {}
}

// MARK: - Pill Views

private struct RecordingPillView: View {
    let startTime: Date
    @State private var isPulsing = false
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 14, height: 14)
                .scaleEffect(isPulsing ? 1.3 : 0.8)
                .opacity(isPulsing ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)

            Text(formatTime(elapsed))
                .font(.system(.title3, design: .monospaced).weight(.medium))
                .foregroundStyle(.primary)
        }
        .fixedSize()
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            isPulsing = true
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                elapsed = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct TranscribingPillView: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.regular)
            Text("Processing...")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
        }
        .fixedSize()
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct SuccessPillView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            Text("Done")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
        }
        .fixedSize()
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct ErrorPillView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title3)
            Text(message)
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize()
        }
        .fixedSize()
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
