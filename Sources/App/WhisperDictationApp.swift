import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await appState.setup()
        }
    }
}

@main
struct WhisperDictationApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appDelegate.appState)
        } label: {
            Image(systemName: appDelegate.appState.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
