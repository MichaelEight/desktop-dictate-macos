import AppKit
import SwiftUI

@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    func openSettings(appState: AppState) {
        let work = { [self] in
            if let existing = settingsWindow, existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let view = SettingsView(appState: appState)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Whisper Dictation Settings"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow = window
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }

    func openOnboarding(appState: AppState) {
        let work = { [self] in
            if let existing = onboardingWindow, existing.isVisible {
                existing.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            let view = OnboardingView(appState: appState)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                styleMask: [.titled], // Non-closable — must complete onboarding
                backing: .buffered,
                defer: false
            )
            window.title = "Welcome to Whisper Dictation"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            onboardingWindow = window
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }
}
