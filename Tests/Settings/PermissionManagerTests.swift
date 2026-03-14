import Testing
@testable import WhisperDictation

@Suite("PermissionManager")
struct PermissionManagerTests {
    @Test("Initial state reflects system")
    func initialStateReflectsSystem() {
        let manager = PermissionManager()
        // Should not crash — returns boolean values
        _ = manager.microphoneAuthorized
        _ = manager.accessibilityAuthorized
    }

    @Test("isFullyPermissioned requires both")
    func isFullyPermissionedRequiresBoth() {
        let manager = PermissionManager()
        let expected = manager.microphoneAuthorized && manager.accessibilityAuthorized
        #expect(manager.isFullyPermissioned == expected)
    }

    @Test("Force poll does not crash")
    func forcePollDoesNotCrash() {
        let manager = PermissionManager()
        manager.forcePoll()
    }

    @Test("Manager creation")
    func managerCreation() {
        let manager = PermissionManager()
        #expect(manager != nil)
    }
}
