import Foundation
import SwiftWhisper
import os

@Observable
final class WhisperManager {
    private(set) var isModelLoaded: Bool = false

    private var whisper: Whisper?
    private var promptPtr: UnsafeMutablePointer<CChar>?

    func loadModel(at url: URL, language: String = "en") async throws {
        Logger.transcription.info("Loading model from \(url.path)")
        let params = WhisperParams(strategy: .greedy)
        params.language = WhisperLanguage(rawValue: language) ?? .english
        params.translate = false
        params.print_special = false
        params.print_progress = false
        params.print_realtime = false
        params.print_timestamps = false
        whisper = Whisper(fromFileURL: url, withParams: params)
        isModelLoaded = true
        Logger.transcription.info("Model loaded successfully")
    }

    func setPrompt(_ prompt: String, vocabulary: String = "") {
        if let old = promptPtr { free(old) }
        let vocabTrimmed = vocabulary.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined: String
        if vocabTrimmed.isEmpty {
            combined = prompt
        } else {
            combined = vocabTrimmed + ". " + prompt
        }
        promptPtr = strdup(combined)
    }

    func transcribe(audioFrames: [Float]) async throws -> String {
        guard let whisper else {
            throw WhisperManagerError.modelNotLoaded
        }

        if let promptPtr {
            whisper.params.initial_prompt = UnsafePointer(promptPtr)
        }

        Logger.transcription.debug("Transcribing \(audioFrames.count) audio frames")
        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        let text = segments.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespaces)
        Logger.transcription.info("Transcription complete: \(text.prefix(80))...")
        return text
    }

    deinit {
        if let p = promptPtr { free(p) }
    }
}

enum WhisperManagerError: LocalizedError {
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "No Whisper model is loaded."
        }
    }
}
