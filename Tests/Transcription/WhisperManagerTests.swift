import Testing
@testable import WhisperDictation

@Suite("WhisperManager")
struct WhisperManagerTests {
    @Test("Initial state — model not loaded")
    func initialState() {
        let manager = WhisperManager()
        #expect(manager.isModelLoaded == false)
    }

    @Test("Transcribe without model throws")
    func transcribeWithoutModel() async {
        let manager = WhisperManager()
        do {
            _ = try await manager.transcribe(audioFrames: [0.1, 0.2, 0.3])
            Issue.record("Should throw when no model is loaded")
        } catch {
            #expect(error is WhisperManagerError)
        }
    }

    @Test("Set prompt does not crash")
    func setPrompt() {
        let manager = WhisperManager()
        manager.setPrompt("Use formal English.", vocabulary: "Kubernetes, FastAPI")
    }

    @Test("Set empty prompt does not crash")
    func setEmptyPrompt() {
        let manager = WhisperManager()
        manager.setPrompt("", vocabulary: "")
    }

    @Test("Set prompt multiple times — memory safe")
    func setPromptMultipleTimes() {
        let manager = WhisperManager()
        manager.setPrompt("First prompt")
        manager.setPrompt("Second prompt")
        manager.setPrompt("Third prompt")
    }

    @Test("WhisperManagerError description")
    func errorDescription() {
        let error = WhisperManagerError.modelNotLoaded
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }
}
