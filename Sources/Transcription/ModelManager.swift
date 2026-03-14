import Foundation
import Observation
import os

@Observable
final class ModelManager: NSObject, URLSessionDownloadDelegate {
    var downloadProgress: Double = 0
    var isDownloading: Bool = false
    var downloadingModelId: String?
    var localModelIds: Set<String> = []

    @ObservationIgnored
    private var downloadContinuation: CheckedContinuation<Void, any Error>?
    @ObservationIgnored
    private var pendingDestination: URL?
    @ObservationIgnored
    private var _downloadSession: URLSession?
    private var downloadSession: URLSession {
        if let session = _downloadSession { return session }
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        _downloadSession = session
        return session
    }

    override init() {
        super.init()
        refreshLocalModels()
    }

    func refreshLocalModels() {
        localModelIds = Set(
            AppConstants.availableModels
                .filter { model in
                    let url = modelFileURL(for: model)
                    guard FileManager.default.fileExists(atPath: url.path) else { return false }
                    // Verify file integrity — models must be at least 1 MB
                    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let size = attrs?[.size] as? Int ?? 0
                    if size < 1_000_000 {
                        Logger.model.warning("Model file \(model.id) is too small (\(size) bytes), ignoring")
                        return false
                    }
                    return true
                }
                .map(\.id)
        )
    }

    func downloadModel(_ model: ModelDefinition) async throws {
        guard !isDownloading else {
            throw ModelManagerError.downloadAlreadyInProgress
        }

        try URL.ensureDirectoryExists(.modelsDirectory)

        let destination = modelFileURL(for: model)
        if FileManager.default.fileExists(atPath: destination.path) {
            Logger.model.info("Model \(model.id) already exists on disk")
            refreshLocalModels()
            return
        }

        isDownloading = true
        downloadingModelId = model.id
        downloadProgress = 0
        pendingDestination = destination
        Logger.model.info("Starting download of model \(model.id) from \(model.url)")

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                self.downloadContinuation = continuation
                let task = self.downloadSession.downloadTask(with: model.url)
                task.resume()
            }
            Logger.model.info("Model \(model.id) downloaded to \(destination.path)")
        } catch {
            Logger.model.error("Failed to download model \(model.id): \(error.localizedDescription)")
            isDownloading = false
            downloadingModelId = nil
            throw error
        }

        isDownloading = false
        downloadingModelId = nil
        downloadProgress = 1.0
        refreshLocalModels()
    }

    func availableLocalModels() -> [ModelDefinition] {
        AppConstants.availableModels.filter { localModelIds.contains($0.id) }
    }

    func isModelDownloaded(_ model: ModelDefinition) -> Bool {
        localModelIds.contains(model.id)
    }

    func deleteModel(_ model: ModelDefinition) throws {
        let fileURL = modelFileURL(for: model)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
        Logger.model.info("Deleted model \(model.id)")
        refreshLocalModels()
    }

    func modelFileURL(for model: ModelDefinition) -> URL {
        URL.modelsDirectory.appendingPathComponent(model.filename)
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Must move file here — temp file is deleted when this method returns
        guard let destination = pendingDestination else {
            downloadContinuation?.resume(throwing: ModelManagerError.noDestination)
            downloadContinuation = nil
            return
        }
        do {
            // Remove any existing file at destination
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            downloadContinuation?.resume()
        } catch {
            downloadContinuation?.resume(throwing: error)
        }
        downloadContinuation = nil
        pendingDestination = nil
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress = progress
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error {
            downloadContinuation?.resume(throwing: error)
            downloadContinuation = nil
            pendingDestination = nil
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadingModelId = nil
            }
        }
    }
}

enum ModelManagerError: LocalizedError {
    case downloadAlreadyInProgress
    case noDestination

    var errorDescription: String? {
        switch self {
        case .downloadAlreadyInProgress:
            return "A model download is already in progress."
        case .noDestination:
            return "No destination path set for download."
        }
    }
}
