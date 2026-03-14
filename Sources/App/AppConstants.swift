import Foundation

struct ModelDefinition: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let filename: String
    let url: URL
    let sizeDescription: String
}

enum AppConstants {
    static let availableModels: [ModelDefinition] = [
        ModelDefinition(
            id: "tiny",
            name: "Tiny (75 MB)",
            filename: "ggml-tiny.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin")!,
            sizeDescription: "~75 MB"
        ),
        ModelDefinition(
            id: "base",
            name: "Base (142 MB)",
            filename: "ggml-base.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin")!,
            sizeDescription: "~142 MB"
        ),
        ModelDefinition(
            id: "small",
            name: "Small (466 MB)",
            filename: "ggml-small.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin")!,
            sizeDescription: "~466 MB"
        ),
        ModelDefinition(
            id: "medium",
            name: "Medium (1.5 GB)",
            filename: "ggml-medium.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin")!,
            sizeDescription: "~1.5 GB"
        ),
        ModelDefinition(
            id: "large-v3-turbo-q5",
            name: "Large V3 Turbo Q5 (547 MB)",
            filename: "ggml-large-v3-turbo-q5_0.bin",
            url: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin")!,
            sizeDescription: "~547 MB"
        ),
    ]

    enum Defaults {
        static let modelId = "tiny"
        static let language = "en"
        static let maxRecordingDuration: TimeInterval = 120
        static let initialPrompt = ""
    }

    enum UserDefaultsKeys {
        static let selectedModelId = "selectedModelId"
        static let language = "language"
        static let launchAtLogin = "launchAtLogin"
        static let initialPrompt = "initialPrompt"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let soundFeedback = "soundFeedback"
        static let customVocabulary = "customVocabulary"
        static let keepInClipboard = "keepInClipboard"
        static let maxRecordingDuration = "maxRecordingDuration"
        static let streamingMode = "streamingMode"
    }
}
