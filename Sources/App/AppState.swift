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

    private var maxRecordingTimer: Timer?
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
    func setup() async {
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
        floatingIndicator.show(state: .recording)
        if settingsManager.soundFeedback {
            NSSound(named: "Tink")?.play()
        }
        audioManager.startCapture()

        maxRecordingTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.Defaults.maxRecordingDuration, repeats: false) { [weak self] _ in
            Logger.app.warning("Max recording duration reached")
            self?.stopRecordingAndTranscribe()
        }

        Logger.app.info("Recording started")
    }

    private func stopRecordingAndTranscribe() {
        guard case .recording = recordingState else { return }

        maxRecordingTimer?.invalidate()
        maxRecordingTimer = nil

        if settingsManager.soundFeedback {
            NSSound(named: "Pop")?.play()
        }
        let samples = audioManager.stopCapture()
        Logger.app.info("Recording stopped, \(samples.count) samples captured")

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
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmed.isEmpty {
                    Logger.app.info("Transcription returned empty text")
                    statusMessage = "Ready"
                    floatingIndicator.hide()
                } else {
                    lastTranscription = trimmed
                    let result = textInsertionManager.insertText(trimmed, keepInClipboard: settingsManager.keepInClipboard)
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
}
