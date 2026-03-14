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
    var streamingMode: Bool {
        didSet {
            defaults.set(streamingMode, forKey: AppConstants.UserDefaultsKeys.streamingMode)
            if streamingMode { fastStreamingMode = false }
        }
    }
    var fastStreamingMode: Bool {
        didSet {
            defaults.set(fastStreamingMode, forKey: AppConstants.UserDefaultsKeys.fastStreamingMode)
            if fastStreamingMode { streamingMode = false }
        }
    }
    var textCommandsEnabled: Bool {
        didSet { defaults.set(textCommandsEnabled, forKey: AppConstants.UserDefaultsKeys.textCommandsEnabled) }
    }
    var llmPostProcessingEnabled: Bool {
        didSet { defaults.set(llmPostProcessingEnabled, forKey: AppConstants.UserDefaultsKeys.llmPostProcessingEnabled) }
    }
    var llmApiEndpoint: String {
        didSet { defaults.set(llmApiEndpoint, forKey: AppConstants.UserDefaultsKeys.llmApiEndpoint) }
    }
    var llmApiKey: String {
        didSet { defaults.set(llmApiKey, forKey: AppConstants.UserDefaultsKeys.llmApiKey) }
    }
    var llmModel: String {
        didSet { defaults.set(llmModel, forKey: AppConstants.UserDefaultsKeys.llmModel) }
    }
    var llmSystemPrompt: String {
        didSet { defaults.set(llmSystemPrompt, forKey: AppConstants.UserDefaultsKeys.llmSystemPrompt) }
    }

    var isLargeModelSelected: Bool {
        AppConstants.largeModelIds.contains(selectedModelId)
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
        self.streamingMode = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.streamingMode)
        self.fastStreamingMode = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.fastStreamingMode)
        self.textCommandsEnabled = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.textCommandsEnabled)
        self.llmPostProcessingEnabled = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.llmPostProcessingEnabled)
        self.llmApiEndpoint = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.llmApiEndpoint) ?? "https://api.openai.com/v1/chat/completions"
        self.llmApiKey = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.llmApiKey) ?? ""
        self.llmModel = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.llmModel) ?? "gpt-4o-mini"
        self.llmSystemPrompt = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.llmSystemPrompt) ?? TextPostProcessor.defaultSystemPrompt
    }
}
