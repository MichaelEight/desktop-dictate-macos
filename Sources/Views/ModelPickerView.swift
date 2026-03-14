import SwiftUI

struct ModelPickerView: View {
    let appState: AppState
    @State private var downloadError: String?
    @State private var modelToDelete: ModelDefinition?
    @State private var isLoadingModel = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(AppConstants.availableModels) { model in
                    ModelRow(
                        model: model,
                        isDownloaded: appState.modelManager.isModelDownloaded(model),
                        isSelected: appState.settingsManager.selectedModelId == model.id,
                        isDownloading: appState.modelManager.downloadingModelId == model.id,
                        downloadProgress: appState.modelManager.downloadProgress,
                        onSelect: { selectModel(model) },
                        onDownload: { Task { await downloadModel(model) } },
                        onDelete: { modelToDelete = model }
                    )
                    if model.id != AppConstants.availableModels.last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }

                if let downloadError {
                    Text(downloadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.top, 8)

            // Loading overlay
            if isLoadingModel {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading model...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .confirmationDialog(
            "Delete \(modelToDelete?.name ?? "model")?",
            isPresented: Binding(
                get: { modelToDelete != nil },
                set: { if !$0 { modelToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let model = modelToDelete {
                    deleteModel(model)
                }
                modelToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                modelToDelete = nil
            }
        } message: {
            Text("This will remove the model file from disk. You can re-download it later.")
        }
    }

    private func selectModel(_ model: ModelDefinition) {
        appState.settingsManager.selectedModelId = model.id
        isLoadingModel = true
        Task {
            await appState.loadSelectedModel()
            isLoadingModel = false
        }
    }

    private func downloadModel(_ model: ModelDefinition) async {
        downloadError = nil
        do {
            try await appState.modelManager.downloadModel(model)
            if !appState.modelLoaded {
                selectModel(model)
            }
        } catch {
            downloadError = error.localizedDescription
        }
    }

    private func deleteModel(_ model: ModelDefinition) {
        do {
            try appState.modelManager.deleteModel(model)
            if appState.settingsManager.selectedModelId == model.id {
                appState.modelLoaded = false
                appState.statusMessage = "Model deleted"
            }
        } catch {
            downloadError = error.localizedDescription
        }
    }
}

private struct ModelRow: View {
    let model: ModelDefinition
    let isDownloaded: Bool
    let isSelected: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isSelected && isDownloaded ? Color.green : Color.clear)
                .frame(width: 8, height: 8)

            // Model info
            VStack(alignment: .leading, spacing: 1) {
                Text(model.name)
                    .font(.system(.body, weight: isSelected ? .semibold : .regular))
                Text(model.sizeDescription)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Actions
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .frame(width: 60)
                Text("\(Int(downloadProgress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)
            } else if isDownloaded {
                if !isSelected {
                    Button("Activate") { onSelect() }
                        .controlSize(.small)
                        .buttonStyle(.bordered)
                }
                Button { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            } else {
                Button("Download") { onDownload() }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
