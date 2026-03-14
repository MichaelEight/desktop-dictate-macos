import AppKit
import SwiftUI

/// A small, always-on-top floating pill that shows recording/transcribing status.
/// Visible even when the menu bar popover is closed.
final class FloatingRecordingWindow {
    private var panel: NSPanel?
    private var streamingModel = StreamingTextModel()

    func show(state: RecordingState) {
        hide()

        let view: AnyView
        switch state {
        case .recording:
            streamingModel.text = ""
            view = AnyView(RecordingPillView(startTime: Date(), streamingModel: streamingModel))
        case .transcribing:
            view = AnyView(TranscribingPillView())
        default:
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 60),
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
        panel.contentView = NSHostingView(rootView: view)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 150
            let y = screenFrame.maxY - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.orderFrontRegardless()
        self.panel = panel
    }

    /// Update the streaming transcription text shown in the floating pill.
    func updateStreamingText(_ text: String) {
        streamingModel.text = text
    }

    func showSuccess() {
        hide()

        let view = SuccessPillView()
        let panel = makePanel(width: 100)
        panel.contentView = NSHostingView(rootView: view)
        positionCenter(panel, width: 100)
        panel.orderFrontRegardless()
        self.panel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.hide()
        }
    }

    func showError(_ message: String) {
        hide()

        let view = ErrorPillView(message: message)
        let panel = makePanel(width: 200)
        panel.contentView = NSHostingView(rootView: view)
        positionCenter(panel, width: 200)
        panel.orderFrontRegardless()
        self.panel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.hide()
        }
    }

    func hide() {
        panel?.close()
        panel = nil
        streamingModel.text = ""
    }

    private func makePanel(width: CGFloat) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 32),
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
        return panel
    }

    private func positionCenter(_ panel: NSPanel, width: CGFloat) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.maxY - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

// MARK: - Streaming Text Model

/// Observable model for streaming text, shared between FloatingRecordingWindow and the pill view.
@Observable
class StreamingTextModel {
    var text: String = ""
}

// MARK: - Pill Views

private struct RecordingPillView: View {
    let startTime: Date
    let streamingModel: StreamingTextModel
    @State private var isPulsing = false
    @State private var elapsed: TimeInterval = 0

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.3 : 0.8)
                    .opacity(isPulsing ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)

                Text(formatTime(elapsed))
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(.primary)
            }

            if !streamingModel.text.isEmpty {
                Text(streamingModel.text)
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
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
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Processing...")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct SuccessPillView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
            Text("Done")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct ErrorPillView: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
            Text(message)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
