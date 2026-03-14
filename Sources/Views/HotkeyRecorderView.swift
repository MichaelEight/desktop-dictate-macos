import AppKit
import HotKey
import SwiftUI

/// A view that captures keyboard shortcuts for hotkey configuration.
struct HotkeyRecorderView: View {
    let hotKeyManager: HotKeyManager
    @State private var isRecording = false
    @State private var validationError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                if isRecording {
                    Text("Press new shortcut...")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.orange, lineWidth: 1)
                        )
                } else {
                    Text(hotKeyManager.currentHotkeyDescription)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary)
                        .cornerRadius(6)
                }

                Button(isRecording ? "Cancel" : "Change") {
                    if isRecording {
                        isRecording = false
                        validationError = nil
                    } else {
                        isRecording = true
                        validationError = nil
                    }
                }
                .controlSize(.small)
                .buttonStyle(.hoverBordered)
            }
            .background(
                isRecording ? KeyCaptureView { key, modifiers in
                    handleCapture(key: key, modifiers: modifiers)
                } : nil
            )

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func handleCapture(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Validate: must have at least one modifier
        let hasModifier = modifiers.contains(.command) ||
                          modifiers.contains(.option) ||
                          modifiers.contains(.control) ||
                          modifiers.contains(.shift)

        guard hasModifier else {
            validationError = "Shortcut must include a modifier key (Cmd, Option, Control, or Shift)"
            return
        }

        // Validate: Escape without modifiers cancels
        if key == .escape && !modifiers.contains(.command) && !modifiers.contains(.option) {
            isRecording = false
            validationError = nil
            return
        }

        hotKeyManager.updateHotKey(key: key, modifiers: modifiers)
        isRecording = false
        validationError = nil
    }
}

/// NSViewRepresentable that captures key events for hotkey recording.
private struct KeyCaptureView: NSViewRepresentable {
    let onCapture: (Key, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onCapture = onCapture
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onCapture = onCapture
    }
}

private class KeyCaptureNSView: NSView {
    var onCapture: ((Key, NSEvent.ModifierFlags) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard let key = Key(carbonKeyCode: UInt32(event.keyCode)) else { return }
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        onCapture?(key, modifiers)
    }
}
