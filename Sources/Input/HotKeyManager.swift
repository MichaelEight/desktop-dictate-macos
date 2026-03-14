import AppKit
import HotKey
import os

@Observable
final class HotKeyManager {
    private var hotKey: HotKey?

    var onToggle: (() -> Void)?
    private(set) var currentKey: Key = .space
    private(set) var currentModifiers: NSEvent.ModifierFlags = [.option]

    var currentHotkeyDescription: String {
        var parts: [String] = []
        if currentModifiers.contains(.control) { parts.append("Control") }
        if currentModifiers.contains(.option) { parts.append("Option") }
        if currentModifiers.contains(.shift) { parts.append("Shift") }
        if currentModifiers.contains(.command) { parts.append("Cmd") }
        parts.append(currentKey.description)
        return parts.joined(separator: " + ")
    }

    init() {
        loadPersistedHotKey()
        registerHotKey()
    }

    func updateHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        currentKey = key
        currentModifiers = modifiers
        persistHotKey()
        registerHotKey()
        Logger.hotkey.info("Hotkey updated to: \(self.currentHotkeyDescription)")
    }

    private func registerHotKey() {
        hotKey = HotKey(key: currentKey, modifiers: currentModifiers)
        hotKey?.keyDownHandler = { [weak self] in
            Logger.hotkey.debug("Hotkey toggled")
            self?.onToggle?()
        }
    }

    private func loadPersistedHotKey() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode) != nil else {
            // No persisted hotkey — use defaults (Option+Space)
            return
        }
        let keyCode = defaults.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        let modifierRaw = defaults.integer(forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)

        if let key = Key(carbonKeyCode: UInt32(keyCode)) {
            currentKey = key
            currentModifiers = NSEvent.ModifierFlags(rawValue: UInt(modifierRaw))
            Logger.hotkey.info("Loaded persisted hotkey: \(self.currentHotkeyDescription)")
        }
    }

    private func persistHotKey() {
        let defaults = UserDefaults.standard
        defaults.set(Int(currentKey.carbonKeyCode), forKey: AppConstants.UserDefaultsKeys.hotkeyKeyCode)
        defaults.set(Int(currentModifiers.rawValue), forKey: AppConstants.UserDefaultsKeys.hotkeyModifiers)
    }
}
