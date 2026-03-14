import Testing
import Foundation
@testable import WhisperDictation

@Suite("ModelManager")
struct ModelManagerTests {
    @Test("Model file URL contains correct path")
    func modelFileURL() {
        let manager = ModelManager()
        let tiny = AppConstants.availableModels.first { $0.id == "tiny" }!
        let url = manager.modelFileURL(for: tiny)
        #expect(url.path.contains("Models"))
        #expect(url.path.hasSuffix(tiny.filename))
    }

    @Test("Refresh local models does not crash")
    func refreshLocalModels() {
        let manager = ModelManager()
        manager.refreshLocalModels()
        #expect(manager.localModelIds != nil)
    }

    @Test("isModelDownloaded consistency")
    func isModelDownloadedConsistency() {
        let manager = ModelManager()
        let tiny = AppConstants.availableModels.first { $0.id == "tiny" }!
        let downloaded = manager.isModelDownloaded(tiny)
        #expect(downloaded == manager.localModelIds.contains("tiny"))
    }

    @Test("Available local models consistency")
    func availableLocalModelsConsistency() {
        let manager = ModelManager()
        let localModels = manager.availableLocalModels()
        for model in localModels {
            #expect(manager.localModelIds.contains(model.id))
        }
    }

    @Test("Delete nonexistent model does not throw")
    func deleteNonexistentModel() throws {
        let manager = ModelManager()
        let fakeModel = ModelDefinition(
            id: "fake",
            name: "Fake",
            filename: "nonexistent.bin",
            url: URL(string: "https://example.com")!,
            sizeDescription: "0 MB"
        )
        try manager.deleteModel(fakeModel)
    }

    @Test("Initial download state")
    func initialDownloadState() {
        let manager = ModelManager()
        #expect(manager.isDownloading == false)
        #expect(manager.downloadProgress == 0)
        #expect(manager.downloadingModelId == nil)
    }

    @Test("Model directory URL is valid")
    func modelDirectoryURL() {
        let dir = URL.modelsDirectory
        #expect(!dir.path.isEmpty)
    }

    @Test("Refresh rejects small files")
    func refreshRejectsSmallFiles() throws {
        let manager = ModelManager()
        let tinyModel = AppConstants.availableModels.first { $0.id == "tiny" }!
        let modelURL = manager.modelFileURL(for: tinyModel)
        let dir = modelURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Create a small file (100 bytes)
        let smallData = Data(repeating: 0, count: 100)
        try smallData.write(to: modelURL)

        manager.refreshLocalModels()
        #expect(!manager.localModelIds.contains("tiny"))

        // Cleanup
        try? FileManager.default.removeItem(at: modelURL)
    }

    @Test("ModelManagerError descriptions")
    func errorDescriptions() {
        let downloadError = ModelManagerError.downloadAlreadyInProgress
        let destError = ModelManagerError.noDestination
        #expect(downloadError.errorDescription != nil)
        #expect(destError.errorDescription != nil)
        #expect(downloadError.errorDescription != destError.errorDescription)
    }
}
