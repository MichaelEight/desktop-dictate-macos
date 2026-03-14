import Testing
@testable import WhisperDictation

@Suite("AudioEngineManager")
struct AudioEngineManagerTests {
    @Test("Stop without start returns empty")
    func stopWithoutStartReturnsEmpty() {
        let manager = AudioEngineManager()
        let samples = manager.stopCapture()
        #expect(samples.isEmpty)
    }

    @Test("Double stop returns empty")
    func doubleStopReturnsEmpty() {
        let manager = AudioEngineManager()
        _ = manager.stopCapture()
        let samples = manager.stopCapture()
        #expect(samples.isEmpty)
    }

    @Test("Manager can be created")
    func managerCreation() {
        let manager = AudioEngineManager()
        #expect(manager != nil)
    }
}
