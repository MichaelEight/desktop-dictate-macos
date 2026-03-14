import Testing
@testable import WhisperDictation

@Suite("AppState")
struct AppStateTests {
    @Test("RecordingState equatable")
    func recordingStateEquatable() {
        #expect(RecordingState.idle == RecordingState.idle)
        #expect(RecordingState.recording == RecordingState.recording)
        #expect(RecordingState.transcribing == RecordingState.transcribing)
        #expect(RecordingState.error("a") == RecordingState.error("a"))
        #expect(RecordingState.error("a") != RecordingState.error("b"))
        #expect(RecordingState.idle != RecordingState.recording)
    }

    @Test("RecordingState.isRecording")
    func recordingStateIsRecording() {
        #expect(RecordingState.recording.isRecording == true)
        #expect(RecordingState.idle.isRecording == false)
        #expect(RecordingState.transcribing.isRecording == false)
        #expect(RecordingState.error("test").isRecording == false)
    }

    // Note: AppState init() creates HotKeyManager which registers global hotkeys
    // via Carbon APIs. This requires an NSApplication context and crashes in the
    // test runner. Tests that need AppState should be run as integration tests
    // with a proper app host, or the subsystems should be tested individually.
}
