import SwiftUI
import AppKit
import os

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
}

@Observable
final class AppState {
    var recordingState: RecordingState = .idle
    var lastTranscription: String = ""
    var modelLoaded: Bool = false
    var statusMessage: String = "Ready"

    let audioManager = AudioEngineManager()
    let whisperManager = WhisperManager()
    let modelManager = ModelManager()
    let hotKeyManager = HotKeyManager()
    let textInsertionManager = TextInsertionManager()
    let settingsManager = SettingsManager()
    let permissionManager = PermissionManager()
    let launchAtLoginManager = LaunchAtLoginManager()
    let floatingIndicator = FloatingRecordingWindow()
    let streamingWhisper = StreamingWhisperManager()

    var streamingTranscription: String = ""

    private var maxRecordingTimer: Timer?
    private var streamingTimer: Timer?
    private var streamInsertedCharCount: Int = 0
    private var fastStreamInsertedCharCount: Int = 0
    private var didSetup = false

    var menuBarIcon: String {
        switch recordingState {
        case .idle:
            return modelLoaded ? "waveform" : "waveform.badge.exclamationmark"
        case .recording:
            return "mic.fill"
        case .transcribing:
            return "ellipsis.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    init() {
        Logger.app.info("AppState initializing")
        setupHotKeyCallbacks()
    }

    /// Called once from AppDelegate.applicationDidFinishLaunching
    @MainActor func setup() async {
        guard !didSetup else { return }
        didSetup = true

        // Request mic if not yet determined (shows native dialog)
        if !permissionManager.microphoneAuthorized {
            await permissionManager.requestMicrophoneAccess()
        }

        // Show onboarding on first launch (hasLaunchedBefore is set by OnboardingView "Done")
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunched {
            WindowManager.shared.openOnboarding(appState: self)
        }

        // Listen for app activate to re-validate model
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.validateSelectedModel()
        }

        await loadSelectedModel()
    }

    /// Re-validate that the selected model file still exists on disk.
    private func validateSelectedModel() {
        guard modelLoaded, let modelDef = settingsManager.selectedModel else { return }
        let fileURL = modelManager.modelFileURL(for: modelDef)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            Logger.app.warning("Selected model file was deleted externally: \(modelDef.id)")
            modelLoaded = false
            statusMessage = "Model file missing"
            modelManager.refreshLocalModels()
        }
    }

    private func setupHotKeyCallbacks() {
        hotKeyManager.onToggle = { [weak self] in
            guard let self else { return }
            switch self.recordingState {
            case .idle:
                self.startRecording()
            case .recording:
                self.stopRecordingAndTranscribe()
            case .transcribing, .error:
                break
            }
        }
    }

    func loadSelectedModel() async {
        guard let modelDef = settingsManager.selectedModel else {
            // If the selected model ID doesn't exist (e.g. removed model), reset to default
            if self.settingsManager.selectedModelId != AppConstants.Defaults.modelId {
                Logger.app.warning("Selected model not found, resetting to default")
                self.settingsManager.selectedModelId = AppConstants.Defaults.modelId
                await loadSelectedModel()
                return
            }
            Logger.app.warning("No model selected")
            statusMessage = "No model selected"
            return
        }

        let fileURL = modelManager.modelFileURL(for: modelDef)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.app.warning("Selected model not downloaded: \(modelDef.id)")
            statusMessage = "Model not downloaded"
            modelLoaded = false
            return
        }

        statusMessage = "Loading model..."
        do {
            try await whisperManager.loadModel(at: fileURL, language: settingsManager.language)
            whisperManager.setPrompt(settingsManager.initialPrompt, vocabulary: settingsManager.customVocabulary)
            modelLoaded = true
            statusMessage = "Ready"
            // Also load model for fast streaming (separate whisper context)
            streamingWhisper.loadModel(at: fileURL, language: settingsManager.language)
            Logger.app.info("Model loaded: \(modelDef.name)")
        } catch {
            modelLoaded = false
            statusMessage = "Failed to load model"
            Logger.app.error("Model load failed: \(error.localizedDescription)")
        }
    }

    private func startRecording() {
        guard modelLoaded else {
            Logger.app.warning("Cannot record — no model loaded")
            recordingState = .error("No model loaded")
            return
        }
        guard permissionManager.microphoneAuthorized else {
            Logger.app.warning("Cannot record — microphone access denied")
            recordingState = .error("Microphone access required")
            return
        }
        guard case .idle = recordingState else {
            Logger.app.warning("Cannot start recording — not idle")
            return
        }

        recordingState = .recording
        statusMessage = "Recording..."
        floatingIndicator.audioLevelProvider = { [weak self] in self?.audioManager.currentLevel ?? 0 }
        floatingIndicator.show(state: .recording)
        if settingsManager.soundFeedback {
            NSSound(named: "Tink")?.play()
        }
        audioManager.startCapture()

        // Start streaming transcription if enabled
        if settingsManager.fastStreamingMode {
            startFastStreaming()
        } else if settingsManager.streamingMode {
            startStreamingTranscription()
        }

        if settingsManager.maxRecordingDuration > 0 {
            maxRecordingTimer = Timer.scheduledTimer(withTimeInterval: settingsManager.maxRecordingDuration, repeats: false) { [weak self] _ in
                Logger.app.warning("Max recording duration reached")
                self?.stopRecordingAndTranscribe()
            }
        }

        Logger.app.info("Recording started")
    }

    private func stopRecordingAndTranscribe() {
        guard case .recording = recordingState else { return }

        maxRecordingTimer?.invalidate()
        maxRecordingTimer = nil
        stopStreamingTranscription()
        stopFastStreaming()

        if settingsManager.soundFeedback {
            NSSound(named: "Pop")?.play()
        }
        let samples = audioManager.stopCapture()
        Logger.app.info("Recording stopped, \(samples.count) samples captured")

        // Fast streaming already inserted text live — always finalize here,
        // never fall through to full transcription (two whisper contexts
        // running concurrently can crash)
        if settingsManager.fastStreamingMode {
            if fastStreamInsertedCharCount > 0 {
                lastTranscription = streamingTranscription
                floatingIndicator.showSuccess()
                statusMessage = "Ready"
            } else {
                floatingIndicator.showError("No transcription")
                statusMessage = "No transcription generated"
            }
            streamingTranscription = ""
            fastStreamInsertedCharCount = 0
            recordingState = .idle
            Logger.app.info("Fast streaming finalized")
            return
        }

        guard samples.count > 1600 else {
            Logger.app.info("Recording too short, ignoring")
            recordingState = .idle
            statusMessage = "Ready"
            floatingIndicator.hide()
            return
        }

        recordingState = .transcribing
        statusMessage = "Transcribing..."
        floatingIndicator.show(state: .transcribing)

        Task { @MainActor in
            do {
                let text = try await whisperManager.transcribe(audioFrames: samples)
                var trimmed = TextPostProcessor.filterJunkTokens(
                    text.trimmingCharacters(in: .whitespacesAndNewlines)
                )

                // Post-processing pipeline
                if !trimmed.isEmpty && settingsManager.textCommandsEnabled {
                    trimmed = TextPostProcessor.applyTextCommands(trimmed)
                }
                if !trimmed.isEmpty && settingsManager.llmPostProcessingEnabled && !settingsManager.llmApiKey.isEmpty {
                    statusMessage = "Polishing..."
                    do {
                        trimmed = try await TextPostProcessor.llmProcess(
                            text: trimmed,
                            endpoint: settingsManager.llmApiEndpoint,
                            apiKey: settingsManager.llmApiKey,
                            model: settingsManager.llmModel,
                            systemPrompt: settingsManager.llmSystemPrompt
                        )
                    } catch {
                        Logger.app.error("LLM post-processing failed: \(error.localizedDescription)")
                    }
                }

                if trimmed.isEmpty {
                    Logger.app.info("Transcription returned empty text")
                    statusMessage = "Ready"
                    floatingIndicator.hide()
                } else {
                    lastTranscription = trimmed

                    // In streaming mode, delete what streaming inserted, then insert final full text
                    let result: InsertionResult
                    if settingsManager.streamingMode && streamInsertedCharCount > 0 {
                        result = textInsertionManager.replaceStreamingText(
                            oldLength: streamInsertedCharCount,
                            newText: trimmed
                        )
                        streamInsertedCharCount = 0
                    } else {
                        result = textInsertionManager.insertText(trimmed, keepInClipboard: settingsManager.keepInClipboard)
                    }

                    switch result {
                        case .success:
                            statusMessage = "Ready"
                            floatingIndicator.showSuccess()
                            Logger.app.info("Transcription inserted: \(trimmed.prefix(80))")
                        case .accessibilityDenied:
                            statusMessage = "Accessibility permission required"
                            floatingIndicator.showError("Accessibility denied")
                            recordingState = .error("Accessibility permission required")
                            Logger.app.error("Text insertion failed — accessibility denied")
                        case .simulationFailed:
                            statusMessage = "Text insertion failed"
                            floatingIndicator.showError("Paste failed")
                            recordingState = .error("Could not simulate paste")
                            Logger.app.error("Text insertion failed — CGEvent creation failed")
                    }
                }
            } catch {
                Logger.app.error("Transcription failed: \(error.localizedDescription)")
                statusMessage = "Transcription failed"
                floatingIndicator.showError("Transcription failed")
                recordingState = .error(error.localizedDescription)
                try? await Task.sleep(for: .seconds(3))
            }
            recordingState = .idle
        }
    }

    // MARK: - Chunked Streaming Transcription (BROKEN — DO NOT USE)
    // BUG: This mode uses backspace key simulation to delete previously inserted text
    // before replacing it with updated transcription. However, the backspace count is
    // tracked by character count which does not account for text the user typed or
    // that was already present. This causes it to DELETE EXISTING TEXT outside of the
    // transcription, corrupting the user's document. Kept in code for reference but
    // hidden from all UI surfaces. The fast streaming (C API) mode works correctly
    // because it only appends new segments without deleting anything.

    private func startStreamingTranscription() {
        streamingTranscription = ""
        streamInsertedCharCount = 0
        scheduleNextStreamingChunk()
    }

    private func stopStreamingTranscription() {
        streamingTimer?.invalidate()
        streamingTimer = nil
    }

    /// Schedule the next streaming chunk. We use one-shot timers instead of repeating
    /// to avoid overlapping transcriptions — each chunk schedules the next only after completing.
    private func scheduleNextStreamingChunk() {
        streamingTimer?.invalidate()
        streamingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.performStreamingTranscription()
        }
    }

    private func performStreamingTranscription() {
        guard case .recording = recordingState else { return }

        let samples = audioManager.snapshotAudio()
        guard samples.count > 16000 else {
            scheduleNextStreamingChunk()
            return
        }

        Logger.app.debug("Streaming: transcribing \(samples.count) samples")

        Task { @MainActor in
            do {
                let text = try await whisperManager.transcribe(audioFrames: samples)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, case .recording = recordingState {
                    streamingTranscription = trimmed
                    floatingIndicator.updateStreamingText(trimmed)

                    // Delete previously inserted streaming text, then insert full new text
                    let result = textInsertionManager.replaceStreamingText(
                        oldLength: streamInsertedCharCount,
                        newText: trimmed
                    )
                    if result == .success {
                        streamInsertedCharCount = trimmed.count
                    }

                    Logger.app.debug("Streaming result: \(trimmed.prefix(80))")
                }
            } catch {
                Logger.app.error("Streaming transcription failed: \(error.localizedDescription)")
            }
            if case .recording = recordingState {
                scheduleNextStreamingChunk()
            }
        }
    }

    // MARK: - Fast Streaming (C API)

    private func startFastStreaming() {
        streamingTranscription = ""
        fastStreamInsertedCharCount = 0

        // Wire audio samples directly to the streaming whisper manager
        audioManager.onAudioSamples = { [weak self] samples in
            self?.streamingWhisper.feedAudio(samples)
        }

        // When streaming produces a new text segment, append it at cursor
        streamingWhisper.onNewText = { [weak self] (text: String) in
            guard let self, case .recording = self.recordingState else { return }

            // Apply text commands if enabled
            var processed = text
            if self.settingsManager.textCommandsEnabled {
                processed = TextPostProcessor.applyTextCommands(processed)
            }
            guard !processed.isEmpty else { return }

            // Append this segment's text
            if !self.streamingTranscription.isEmpty {
                self.streamingTranscription += " "
            }
            self.streamingTranscription += processed
            self.floatingIndicator.updateStreamingText(self.streamingTranscription)

            // Insert the new segment at cursor (just append, no backspace needed)
            let insertText = (self.fastStreamInsertedCharCount > 0 ? " " : "") + processed
            let result = self.textInsertionManager.insertText(insertText, keepInClipboard: true)
            if result == .success {
                self.fastStreamInsertedCharCount += insertText.count
            }
        }

        streamingWhisper.start()
    }

    private func stopFastStreaming() {
        // Stop feeding new audio and stop the streaming loop
        audioManager.onAudioSamples = nil
        streamingWhisper.stop()

        // Flush remaining audio that hadn't reached the 3s threshold yet
        if let finalText = streamingWhisper.flushRemaining() {
            var processed = finalText
            if settingsManager.textCommandsEnabled {
                processed = TextPostProcessor.applyTextCommands(processed)
            }
            if !processed.isEmpty {
                if !streamingTranscription.isEmpty {
                    streamingTranscription += " "
                }
                streamingTranscription += processed

                let insertText = (fastStreamInsertedCharCount > 0 ? " " : "") + processed
                let result = textInsertionManager.insertText(insertText, keepInClipboard: true)
                if result == .success {
                    fastStreamInsertedCharCount += insertText.count
                }
                Logger.app.info("Fast streaming: flushed final segment: \(processed.prefix(60))")
            }
        }

        streamingWhisper.onNewText = nil
    }
}
