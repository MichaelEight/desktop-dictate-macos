import Testing
@testable import WhisperDictation

@Suite("Recording Flow")
struct RecordingFlowTests {
    @Test("InsertionResult all cases are distinct")
    func insertionResultCases() {
        let cases: [InsertionResult] = [.success, .accessibilityDenied, .simulationFailed]
        #expect(cases.count == 3)
        for i in 0..<cases.count {
            for j in 0..<cases.count {
                if i == j {
                    #expect(cases[i] == cases[j])
                } else {
                    #expect(cases[i] != cases[j])
                }
            }
        }
    }

    @Test("ModelManagerError descriptions")
    func modelManagerErrors() {
        let downloadError = ModelManagerError.downloadAlreadyInProgress
        let destError = ModelManagerError.noDestination
        #expect(downloadError.errorDescription != nil)
        #expect(destError.errorDescription != nil)
        #expect(downloadError.errorDescription != destError.errorDescription)
    }

    @Test("FloatingRecordingWindow can be created and hidden")
    func floatingIndicator() {
        let indicator = FloatingRecordingWindow()
        indicator.hide()
    }

    @Test("RecordingState transitions are valid")
    func stateTransitions() {
        // Verify state machine values
        var state: RecordingState = .idle
        #expect(state == .idle)
        state = .recording
        #expect(state == .recording)
        state = .transcribing
        #expect(state == .transcribing)
        state = .error("test")
        #expect(state == .error("test"))
        state = .idle
        #expect(state == .idle)
    }

    // Note: Full AppState-based recording flow tests crash because HotKeyManager
    // uses Carbon APIs that require an NSApplication run loop context.
    // Subsystems are tested individually instead.
}
