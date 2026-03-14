import Testing
import ApplicationServices
@testable import WhisperDictation

@Suite("TextInsertionManager")
struct TextInsertionManagerTests {
    @Test("InsertionResult equality")
    func insertionResultEquality() {
        #expect(InsertionResult.success == InsertionResult.success)
        #expect(InsertionResult.accessibilityDenied == InsertionResult.accessibilityDenied)
        #expect(InsertionResult.simulationFailed == InsertionResult.simulationFailed)
        #expect(InsertionResult.success != InsertionResult.accessibilityDenied)
        #expect(InsertionResult.success != InsertionResult.simulationFailed)
    }

    @Test("Insert text checks accessibility first")
    func insertTextChecksAccessibility() {
        let manager = TextInsertionManager()
        let result = manager.insertText("test")
        if !AXIsProcessTrusted() {
            #expect(result == .accessibilityDenied)
        } else {
            #expect(result == .success)
        }
    }

    @Test("Insert text with keepInClipboard")
    func insertTextWithKeepInClipboard() {
        let manager = TextInsertionManager()
        let result = manager.insertText("test", keepInClipboard: true)
        if !AXIsProcessTrusted() {
            #expect(result == .accessibilityDenied)
        }
    }

    @Test("Empty text insertion doesn't crash")
    func emptyTextInsertion() {
        let manager = TextInsertionManager()
        _ = manager.insertText("")
    }

    @Test("Special characters don't crash")
    func specialCharacters() {
        let manager = TextInsertionManager()
        _ = manager.insertText("Hello! 🎉 café naïve über")
    }

    @Test("Very long text doesn't crash")
    func veryLongText() {
        let manager = TextInsertionManager()
        let longText = String(repeating: "a", count: 10_000)
        _ = manager.insertText(longText)
    }

    @Test("Manager can be created")
    func managerCreation() {
        let manager = TextInsertionManager()
        #expect(manager != nil)
    }

    @Test("All InsertionResult cases are distinct")
    func allCasesDistinct() {
        let cases: [InsertionResult] = [.success, .accessibilityDenied, .simulationFailed]
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
}
