import ServiceManagement
import os

@Observable
final class LaunchAtLoginManager {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                Logger.app.info("Launch at login enabled")
            } else {
                try SMAppService.mainApp.unregister()
                Logger.app.info("Launch at login disabled")
            }
        } catch {
            Logger.app.error("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
