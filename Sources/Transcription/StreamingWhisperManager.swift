import Foundation
import whisper_cpp
import os

/// Real-time streaming transcription using whisper.cpp C API directly.
/// Uses a sliding window: waits for ~3s of new audio, transcribes it, emits text, moves on.
/// Only the last 200ms is kept as overlap for word-boundary context.
final class StreamingWhisperManager {
    private var context: OpaquePointer?
    private var isRunning = false
    private var loopExited = false
    private var processingQueue = DispatchQueue(label: "streaming-whisper", qos: .userInitiated)

    // Sliding window parameters
    private let stepMs: Int = 3000      // Process every 3s of new audio
    private let keepMs: Int = 200       // Overlap from previous window for context

    // Audio buffer — new samples accumulate here, consumed after each transcription
    private var audioBuffer: [Float] = []
    private let audioLock = NSLock()

    // Callback for new text
    var onNewText: ((String) -> Void)?

    private var language: String = "en"

    // Patterns to filter from output
    private static let junkPatterns: [String] = [
        "[BLANK_AUDIO]", "(BLANK_AUDIO)", "[silence]", "(silence)",
        "[Music]", "(Music)", "[music]", "(music)",
        "(gentle music)", "(sighs)", "(laughs)", "(applause)",
        "(coughing)", "(breathing)", "(clicking)", "(typing)",
        "[inaudible]", "(inaudible)",
    ]

    /// Minimum RMS energy threshold — below this the audio is considered silence.
    private let silenceThreshold: Float = 0.003

    func loadModel(at url: URL, language: String = "en") {
        self.language = language
        context = url.path.withCString { whisper_init_from_file($0) }
        if context != nil {
            Logger.transcription.info("StreamingWhisperManager: model loaded")
        } else {
            Logger.transcription.error("StreamingWhisperManager: failed to load model")
        }
    }

    func start() {
        guard context != nil else {
            Logger.transcription.error("StreamingWhisperManager: no model loaded")
            return
        }

        audioLock.lock()
        audioBuffer.removeAll()
        audioLock.unlock()

        isRunning = true
        loopExited = false
        processingQueue.async { [weak self] in
            self?.streamingLoop()
            self?.loopExited = true
        }
        Logger.transcription.info("StreamingWhisperManager: started")
    }

    /// Stop streaming. Sets the flag so the loop exits after current iteration.
    /// Does NOT block the main thread (avoids deadlock with onNewText callback).
    func stop() {
        isRunning = false
        Logger.transcription.info("StreamingWhisperManager: stop requested")
    }

    /// Flush any remaining audio in the buffer through one final transcription.
    /// Call AFTER stop() and after the loop has exited. Returns the final text or nil.
    func flushRemaining() -> String? {
        audioLock.lock()
        let remaining = audioBuffer
        audioBuffer.removeAll()
        audioLock.unlock()

        guard remaining.count > 1600 else { return nil } // too short
        guard rmsEnergy(remaining) >= silenceThreshold else { return nil } // silence

        Logger.transcription.info("StreamingWhisperManager: flushing \(remaining.count) remaining samples")
        return transcribeWindow(remaining)
    }

    /// Feed new audio samples from the microphone capture.
    func feedAudio(_ samples: [Float]) {
        audioLock.lock()
        audioBuffer.append(contentsOf: samples)
        audioLock.unlock()
    }

    /// The main streaming loop — runs on background queue.
    private func streamingLoop() {
        let sampleRate = 16000
        let nSamplesStep = (stepMs * sampleRate) / 1000
        let nSamplesKeep = (keepMs * sampleRate) / 1000

        while isRunning {
            // Wait until we have enough new audio
            var currentCount = 0
            repeat {
                if !isRunning { return }
                Thread.sleep(forTimeInterval: 0.05)
                audioLock.lock()
                currentCount = audioBuffer.count
                audioLock.unlock()
            } while currentCount < nSamplesStep

            // Grab all buffered audio and consume it (keep only overlap tail)
            audioLock.lock()
            let samples = audioBuffer
            // Keep only the last keepMs for next iteration's overlap
            if audioBuffer.count > nSamplesKeep {
                audioBuffer = Array(audioBuffer.suffix(nSamplesKeep))
            }
            audioLock.unlock()

            guard samples.count > 0 else { continue }

            // Skip silent audio — no point sending silence to Whisper
            if rmsEnergy(samples) < silenceThreshold {
                continue
            }

            // Transcribe this chunk
            let text = transcribeWindow(samples)
            if let text, !text.isEmpty, isRunning {
                DispatchQueue.main.async { [weak self] in
                    self?.onNewText?(text)
                }
            }
        }
    }

    /// Transcribe a single audio window using whisper_full with streaming-optimized params.
    private func transcribeWindow(_ samples: [Float]) -> String? {
        guard let ctx = context else { return nil }

        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.single_segment = true
        params.no_context = true
        params.print_progress = false
        params.print_special = false
        params.print_realtime = false
        params.print_timestamps = false
        params.translate = false
        // Use fewer threads than available to avoid starving the audio subsystem
        params.n_threads = Int32(max(min(ProcessInfo.processInfo.activeProcessorCount / 2, 4), 2))
        params.suppress_blank = true

        // Set language
        let langCStr = strdup(language == "auto" ? "auto" : language)
        params.language = UnsafePointer(langCStr)
        defer { free(langCStr) }

        let result = samples.withUnsafeBufferPointer { buf -> Int32 in
            whisper_full(ctx, params, buf.baseAddress!, Int32(samples.count))
        }

        guard result == 0 else {
            Logger.transcription.error("StreamingWhisperManager: whisper_full failed with \(result)")
            return nil
        }

        let nSegments = whisper_full_n_segments(ctx)
        var text = ""
        for i in 0..<nSegments {
            if let segText = whisper_full_get_segment_text(ctx, i) {
                text += String(cString: segText)
            }
        }

        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Filter junk tokens
        for pattern in Self.junkPatterns {
            trimmed = trimmed.replacingOccurrences(of: pattern, with: "")
        }

        // Remove any remaining (parenthetical) or [bracketed] noise descriptions
        trimmed = trimmed.replacingOccurrences(
            of: "\\([^)]*\\)|\\[[^\\]]*\\]",
            with: "",
            options: .regularExpression
        )

        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)

        // Skip very short outputs — likely hallucinations from noise
        if trimmed.count < 3 { return nil }

        return trimmed.isEmpty ? nil : trimmed
    }

    /// Compute RMS energy of audio samples. Low values = silence.
    private func rmsEnergy(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(samples.count))
    }

    deinit {
        isRunning = false
        if let ctx = context {
            whisper_free(ctx)
        }
    }
}
