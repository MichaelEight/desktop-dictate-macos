import Testing
@testable import WhisperDictation

@Suite("AppConstants")
struct AppConstantsTests {
    @Test("All models have unique IDs")
    func allModelsHaveUniqueIds() {
        let ids = AppConstants.availableModels.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("All models have valid HTTPS URLs")
    func allModelsHaveValidURLs() {
        for model in AppConstants.availableModels {
            #expect(model.url.scheme != nil)
            #expect(model.url.absoluteString.hasPrefix("https://"))
        }
    }

    @Test("All models have .bin filenames")
    func allModelsHaveFilenames() {
        for model in AppConstants.availableModels {
            #expect(!model.filename.isEmpty)
            #expect(model.filename.hasSuffix(".bin"))
        }
    }

    @Test("Default model exists in available models")
    func defaultModelExists() {
        let defaultModel = AppConstants.availableModels.first { $0.id == AppConstants.Defaults.modelId }
        #expect(defaultModel != nil)
    }

    @Test("All models have size descriptions")
    func allModelsHaveSizeDescriptions() {
        for model in AppConstants.availableModels {
            #expect(!model.sizeDescription.isEmpty)
        }
    }

    @Test("All models have names")
    func allModelsHaveNames() {
        for model in AppConstants.availableModels {
            #expect(!model.name.isEmpty)
        }
    }

    @Test("Default language is valid")
    func defaultLanguageIsValid() {
        #expect(!AppConstants.Defaults.language.isEmpty)
    }

    @Test("Max recording duration is reasonable")
    func maxRecordingDurationIsReasonable() {
        #expect(AppConstants.Defaults.maxRecordingDuration > 0)
        #expect(AppConstants.Defaults.maxRecordingDuration <= 300)
    }

    @Test("ModelDefinition Equatable")
    func modelDefinitionEquatable() {
        let model1 = AppConstants.availableModels[0]
        let model2 = AppConstants.availableModels[0]
        let model3 = AppConstants.availableModels[1]
        #expect(model1 == model2)
        #expect(model1 != model3)
    }

    @Test("ModelDefinition Identifiable")
    func modelDefinitionIdentifiable() {
        for model in AppConstants.availableModels {
            #expect(!model.id.isEmpty)
        }
    }
}
