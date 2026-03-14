import os

extension Logger {
    private static let subsystem = "com.whisper-dictation.app"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    static let permissions = Logger(subsystem: subsystem, category: "permissions")
    static let model = Logger(subsystem: subsystem, category: "model")
}
