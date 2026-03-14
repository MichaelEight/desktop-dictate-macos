import AVFoundation
import ApplicationServices
import AppKit
import os

@Observable
final class PermissionManager {
    var microphoneAuthorized = false
    var accessibilityAuthorized = false

    var isFullyPermissioned: Bool {
        microphoneAuthorized && accessibilityAuthorized
    }

    private var pollTimer: Timer?

    init() {
        // Check mic status synchronously (no dialog)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneAuthorized = (status == .authorized)

        // Check accessibility synchronously
        accessibilityAuthorized = AXIsProcessTrusted()

        // Poll both permissions every 5 seconds to stay in sync
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.poll()
        }

        Logger.permissions.info("Permissions init — mic: \(self.microphoneAuthorized), accessibility: \(self.accessibilityAuthorized)")
    }

    /// Shows the native macOS mic permission dialog. Async — resolves when user responds.
    func requestMicrophoneAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            self.microphoneAuthorized = granted
        }
        Logger.permissions.info("Mic access request result: \(granted)")
    }

    func forcePoll() {
        poll()
    }

    /// Prompts for accessibility if not trusted, showing the system dialog.
    /// This uses AXIsProcessTrustedWithOptions which triggers the macOS
    /// "allow accessibility" alert automatically.
    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        accessibilityAuthorized = trusted
        if !trusted {
            Logger.permissions.info("Accessibility prompt shown to user")
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func poll() {
        let mic = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let ax = AXIsProcessTrusted()

        if mic != microphoneAuthorized {
            microphoneAuthorized = mic
            Logger.permissions.info("Mic permission changed: \(mic)")
        }
        if ax != accessibilityAuthorized {
            accessibilityAuthorized = ax
            Logger.permissions.info("Accessibility permission changed: \(ax)")
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}
