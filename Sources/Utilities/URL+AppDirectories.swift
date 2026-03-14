import Foundation

extension URL {
    static var appSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WhisperDictation", isDirectory: true)
    }

    static var modelsDirectory: URL {
        appSupportDirectory.appendingPathComponent("Models", isDirectory: true)
    }

    static func ensureDirectoryExists(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
