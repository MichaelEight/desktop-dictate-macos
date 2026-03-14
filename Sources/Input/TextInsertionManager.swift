import ApplicationServices
import AppKit
import Carbon
import os

enum InsertionResult: Equatable {
    case success
    case accessibilityDenied
    case simulationFailed
}

final class TextInsertionManager {
    private let keycodeResolver = KeycodeResolver()

    func insertText(_ text: String, keepInClipboard: Bool = false) -> InsertionResult {
        // Pre-check accessibility BEFORE touching clipboard
        guard AXIsProcessTrusted() else {
            Logger.hotkey.warning("Accessibility not trusted — aborting text insertion")
            return .accessibilityDenied
        }

        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Use layout-independent keycode for 'v'
        let keyCode = keycodeResolver.keycode(for: "v")

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            Logger.hotkey.error("Failed to create CGEvent for Cmd+V")
            // Restore clipboard since we modified it but can't paste
            pasteboard.clearContents()
            if let oldContents {
                pasteboard.setString(oldContents, forType: .string)
            }
            return .simulationFailed
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)

        Logger.hotkey.debug("Simulated Cmd+V to insert text")

        if !keepInClipboard {
            // Adaptive clipboard restore: poll changeCount then fallback to 500ms
            let changeCountBefore = pasteboard.changeCount
            adaptiveRestore(pasteboard: pasteboard, oldContents: oldContents, changeCountBefore: changeCountBefore)
        }

        return .success
    }

    /// Poll pasteboard changeCount every 50ms up to 1s. If the target app reads the paste
    /// (changeCount increments), restore immediately. Otherwise restore after 500ms.
    private func adaptiveRestore(pasteboard: NSPasteboard, oldContents: String?, changeCountBefore: Int) {
        let maxPolls = 10  // 10 * 50ms = 500ms max
        var pollCount = 0

        func checkAndRestore() {
            pollCount += 1
            if pasteboard.changeCount != changeCountBefore || pollCount >= maxPolls {
                // Target app consumed paste, or timeout — restore now
                pasteboard.clearContents()
                if let oldContents {
                    pasteboard.setString(oldContents, forType: .string)
                }
                Logger.hotkey.debug("Restored original pasteboard contents after \(pollCount * 50)ms")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    checkAndRestore()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            checkAndRestore()
        }
    }
}
