import Foundation

@Observable
final class SettingsManager {
    private let defaults = UserDefaults.standard

    var selectedModelId: String {
        didSet { defaults.set(selectedModelId, forKey: AppConstants.UserDefaultsKeys.selectedModelId) }
    }
    var language: String {
        didSet { defaults.set(language, forKey: AppConstants.UserDefaultsKeys.language) }
    }
    var initialPrompt: String {
        didSet { defaults.set(initialPrompt, forKey: AppConstants.UserDefaultsKeys.initialPrompt) }
    }
    var soundFeedback: Bool {
        didSet { defaults.set(soundFeedback, forKey: AppConstants.UserDefaultsKeys.soundFeedback) }
    }
    var customVocabulary: String {
        didSet { defaults.set(customVocabulary, forKey: AppConstants.UserDefaultsKeys.customVocabulary) }
    }
    var keepInClipboard: Bool {
        didSet { defaults.set(keepInClipboard, forKey: AppConstants.UserDefaultsKeys.keepInClipboard) }
    }
    var maxRecordingDuration: TimeInterval {
        didSet { defaults.set(maxRecordingDuration, forKey: AppConstants.UserDefaultsKeys.maxRecordingDuration) }
    }

    var selectedModel: ModelDefinition? {
        AppConstants.availableModels.first { $0.id == selectedModelId }
    }

    init() {
        self.selectedModelId = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedModelId) ?? AppConstants.Defaults.modelId
        self.language = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.language) ?? AppConstants.Defaults.language
        self.initialPrompt = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.initialPrompt) ?? ""
        let hasSoundKey = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.soundFeedback) != nil
        self.soundFeedback = hasSoundKey ? UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.soundFeedback) : true
        self.customVocabulary = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.customVocabulary) ?? ""
        self.keepInClipboard = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.keepInClipboard)
        let hasDurationKey = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.maxRecordingDuration) != nil
        self.maxRecordingDuration = hasDurationKey ? UserDefaults.standard.double(forKey: AppConstants.UserDefaultsKeys.maxRecordingDuration) : AppConstants.Defaults.maxRecordingDuration
    }
}
