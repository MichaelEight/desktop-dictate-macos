import Testing
@testable import WhisperDictation

@Suite("LaunchAtLoginManager")
struct LaunchAtLoginManagerTests {
    @Test("Manager creation")
    func managerCreation() {
        let manager = LaunchAtLoginManager()
        #expect(manager != nil)
    }

    @Test("isEnabled returns boolean")
    func isEnabledReturnsBoolean() {
        let manager = LaunchAtLoginManager()
        _ = manager.isEnabled
    }

    @Test("setEnabled does not crash")
    func setEnabledDoesNotCrash() {
        let manager = LaunchAtLoginManager()
        manager.setEnabled(false)
    }
}
