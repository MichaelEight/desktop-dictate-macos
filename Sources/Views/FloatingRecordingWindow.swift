import AppKit
import SwiftUI

/// A small, always-on-top floating pill that shows recording/transcribing status.
/// Visible even when the menu bar popover is closed.
final class FloatingRecordingWindow {
    private var panel: NSPanel?

    /// Optional closure that returns the current mic RMS level (0.0–~0.5).
    var audioLevelProvider: (() -> Float)?

    func show(state: RecordingState) {
        hide()

        let view: AnyView
        switch state {
        case .recording:
            view = AnyView(RecordingPillView(startTime: Date(), audioLevelProvider: audioLevelProvider))
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
    let audioLevelProvider: (() -> Float)?
    @State private var isPulsing = false
    @State private var elapsed: TimeInterval = 0
    @State private var audioLevel: Float = 0

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

            AudioLevelBars(level: audioLevel)
        }
        .fixedSize()
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            isPulsing = true
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsed = Date().timeIntervalSince(startTime)
                audioLevel = audioLevelProvider?() ?? 0
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Mini audio level indicator — 5 vertical bars that respond to mic input.
private struct AudioLevelBars: View {
    let level: Float

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 3, height: barHeight(for: i))
            }
        }
        .frame(height: 16)
        .animation(.easeOut(duration: 0.08), value: level)
    }

    private var barColor: Color {
        let norm = min(Double(level) * 40, 1.0)
        if norm > 0.5 { return .green }
        if norm > 0.1 { return .green.opacity(0.7) }
        return .primary.opacity(0.2)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let norm = min(CGFloat(level) * 40, 1.0)
        // Middle bar tallest, edges shorter
        let weights: [CGFloat] = [0.5, 0.8, 1.0, 0.75, 0.55]
        return max(3, 16 * norm * weights[index])
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
