import Testing
import Foundation
@testable import WhisperDictation

@Suite("SettingsManager", .serialized)
struct SettingsManagerTests {
    private static let testKeys = [
        AppConstants.UserDefaultsKeys.selectedModelId,
        AppConstants.UserDefaultsKeys.language,
        AppConstants.UserDefaultsKeys.initialPrompt,
        AppConstants.UserDefaultsKeys.soundFeedback,
        AppConstants.UserDefaultsKeys.customVocabulary,
        AppConstants.UserDefaultsKeys.keepInClipboard,
    ]

    private func cleanDefaults() {
        for key in Self.testKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    @Test("Default selected model ID")
    func defaultSelectedModelId() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.selectedModelId == AppConstants.Defaults.modelId)
        cleanDefaults()
    }

    @Test("Default language is English")
    func defaultLanguage() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.language == AppConstants.Defaults.language)
        cleanDefaults()
    }

    @Test("Default sound feedback is true")
    func defaultSoundFeedback() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.soundFeedback == true)
        cleanDefaults()
    }

    @Test("Default initial prompt is empty")
    func defaultInitialPrompt() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.initialPrompt == "")
        cleanDefaults()
    }

    @Test("Default custom vocabulary is empty")
    func defaultCustomVocabulary() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.customVocabulary == "")
        cleanDefaults()
    }

    @Test("Default keep in clipboard is false")
    func defaultKeepInClipboard() {
        cleanDefaults()
        let manager = SettingsManager()
        #expect(manager.keepInClipboard == false)
        cleanDefaults()
    }

    @Test("Persist selected model ID")
    func persistSelectedModelId() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.selectedModelId = "base"
        let reloaded = SettingsManager()
        #expect(reloaded.selectedModelId == "base")
        cleanDefaults()
    }

    @Test("Persist language")
    func persistLanguage() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.language = "fr"
        let reloaded = SettingsManager()
        #expect(reloaded.language == "fr")
        cleanDefaults()
    }

    @Test("Persist initial prompt")
    func persistInitialPrompt() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.initialPrompt = "Use formal English."
        let reloaded = SettingsManager()
        #expect(reloaded.initialPrompt == "Use formal English.")
        cleanDefaults()
    }

    @Test("Persist sound feedback")
    func persistSoundFeedback() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.soundFeedback = false
        let reloaded = SettingsManager()
        #expect(reloaded.soundFeedback == false)
        cleanDefaults()
    }

    @Test("Persist custom vocabulary")
    func persistCustomVocabulary() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.customVocabulary = "Kubernetes, FastAPI"
        let reloaded = SettingsManager()
        #expect(reloaded.customVocabulary == "Kubernetes, FastAPI")
        cleanDefaults()
    }

    @Test("Persist keep in clipboard")
    func persistKeepInClipboard() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.keepInClipboard = true
        let reloaded = SettingsManager()
        #expect(reloaded.keepInClipboard == true)
        cleanDefaults()
    }

    @Test("Selected model returns correct model")
    func selectedModelReturnsCorrectModel() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.selectedModelId = "tiny"
        #expect(manager.selectedModel != nil)
        #expect(manager.selectedModel?.id == "tiny")
        cleanDefaults()
    }

    @Test("Selected model returns nil for invalid ID")
    func selectedModelReturnsNilForInvalidId() {
        cleanDefaults()
        let manager = SettingsManager()
        manager.selectedModelId = "nonexistent-model"
        #expect(manager.selectedModel == nil)
        cleanDefaults()
    }

    @Test("Multiple rapid changes persist")
    func multipleRapidChanges() {
        cleanDefaults()
        let manager = SettingsManager()
        for i in 0..<100 {
            manager.language = "lang\(i)"
        }
        #expect(manager.language == "lang99")
        let reloaded = SettingsManager()
        #expect(reloaded.language == "lang99")
        cleanDefaults()
    }
}
