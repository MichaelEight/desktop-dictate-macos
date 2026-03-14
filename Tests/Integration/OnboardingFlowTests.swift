import Testing
import Foundation
@testable import WhisperDictation

@Suite("Onboarding Flow", .serialized)
struct OnboardingFlowTests {
    @Test("hasLaunchedBefore defaults to false")
    func hasLaunchedBeforeDefaultsFalse() {
        UserDefaults.standard.removeObject(forKey: "hasLaunchedBefore")
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        #expect(hasLaunched == false)
    }

    @Test("hasLaunchedBefore persists when set")
    func hasLaunchedBeforePersists() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        #expect(hasLaunched == true)
        UserDefaults.standard.removeObject(forKey: "hasLaunchedBefore")
    }

    @Test("Permission manager isFullyPermissioned matches both properties")
    func permissionManagerFullyPermissioned() {
        let manager = PermissionManager()
        let expected = manager.microphoneAuthorized && manager.accessibilityAuthorized
        #expect(manager.isFullyPermissioned == expected)
    }

    // Note: Cannot test AppState.setup() or OnboardingView directly because
    // HotKeyManager uses Carbon APIs requiring NSApplication context.
}
