import Carbon
import Foundation

/// Resolves the correct virtual keycode for a character based on the current keyboard layout.
/// Caches results and invalidates when the keyboard input source changes.
final class KeycodeResolver {
    private var cache: [Character: CGKeyCode] = [:]
    private var currentInputSourceId: String?

    /// Returns the virtual keycode that produces the given character on the current keyboard layout.
    /// Falls back to QWERTY keycode if lookup fails.
    func keycode(for character: Character) -> CGKeyCode {
        let inputSourceId = currentInputSourceIdentifier()

        // Invalidate cache if keyboard layout changed
        if inputSourceId != currentInputSourceId {
            cache.removeAll()
            currentInputSourceId = inputSourceId
        }

        if let cached = cache[character] {
            return cached
        }

        if let resolved = resolveKeycode(for: character) {
            cache[character] = resolved
            return resolved
        }

        // Fallback to QWERTY keycodes for common characters
        let fallback = qwertyFallback(for: character)
        cache[character] = fallback
        return fallback
    }

    private func currentInputSourceIdentifier() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private func resolveKeycode(for character: Character) -> CGKeyCode? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let layoutPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = Unmanaged<CFData>.fromOpaque(layoutPtr).takeUnretainedValue() as Data
        let target = String(character).lowercased().unicodeScalars.first!

        return layoutData.withUnsafeBytes { rawBuffer -> CGKeyCode? in
            guard let layoutRawPtr = rawBuffer.baseAddress else { return nil }
            let layoutDataPtr = layoutRawPtr.assumingMemoryBound(to: UCKeyboardLayout.self)

            // Scan all possible keycodes (0-127)
            for keyCode: UInt16 in 0..<128 {
                var deadKeyState: UInt32 = 0
                var chars = [UniChar](repeating: 0, count: 4)
                var actualLength: Int = 0

                let status = UCKeyTranslate(
                    layoutDataPtr,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0, // no modifiers
                    UInt32(LMGetKbdType()),
                    UInt32(kUCKeyTranslateNoDeadKeysBit),
                    &deadKeyState,
                    chars.count,
                    &actualLength,
                    &chars
                )

                if status == noErr && actualLength > 0 {
                    let scalar = Unicode.Scalar(chars[0])
                    if scalar == target {
                        return CGKeyCode(keyCode)
                    }
                }
            }
            return nil
        }
    }

    private func qwertyFallback(for character: Character) -> CGKeyCode {
        switch character {
        case "v", "V": return 0x09
        case "c", "C": return 0x08
        case "a", "A": return 0x00
        case "z", "Z": return 0x06
        case "x", "X": return 0x07
        default: return 0x09 // Default to V
        }
    }
}
