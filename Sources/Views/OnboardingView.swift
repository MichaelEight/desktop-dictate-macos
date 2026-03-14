import SwiftUI

struct OnboardingView: View {
    let appState: AppState
    @State private var step = 0
    @State private var waitingForAccessibility = false
    @State private var autoDownloadStarted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Whisper Dictation")
                .font(.title2.weight(.semibold))
                .padding(.top, 24)

            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 8)

            // Content
            Group {
                switch step {
                case 0: permissionsStep
                case 1: modelStep
                default: readyStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                if step < 2 {
                    Button("Next") { step += 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAdvance)
                } else {
                    Button("Done") {
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                        NSApp.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .frame(width: 480, height: 380)
    }

    private var canAdvance: Bool {
        switch step {
        case 0:
            return appState.permissionManager.isFullyPermissioned
        case 1:
            return !appState.modelManager.availableLocalModels().isEmpty
        default:
            return true
        }
    }

    // MARK: - Step 0: Permissions

    private var permissionsStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("Permissions")
                .font(.headline)

            Text("Both permissions are required to continue.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                permRow("mic.fill", "Microphone", "Record your speech",
                        appState.permissionManager.microphoneAuthorized) {
                    Task { await appState.permissionManager.requestMicrophoneAccess() }
                }
                permRow("lock.shield", "Accessibility", "Insert text at cursor",
                        appState.permissionManager.accessibilityAuthorized) {
                    waitingForAccessibility = true
                    appState.permissionManager.requestAccessibilityAccess()
                }
            }
            .padding(.horizontal, 40)

            if waitingForAccessibility && !appState.permissionManager.accessibilityAuthorized {
                accessibilityWaitingOverlay
            }

            if appState.permissionManager.isFullyPermissioned {
                Label("All permissions granted!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 12)
        .onChange(of: appState.permissionManager.accessibilityAuthorized) { _, granted in
            if granted { waitingForAccessibility = false }
        }
    }

    private func permRow(_ icon: String, _ title: String, _ subtitle: String, _ granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: granted ? "\(icon)" : icon)
                .foregroundStyle(granted ? .green : .orange)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout.weight(.medium))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if granted {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                Button("Grant") { action() }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
            }
        }
    }

    private var accessibilityWaitingOverlay: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Waiting for accessibility permission...")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Check Now") {
                // Force an immediate poll
                appState.permissionManager.forcePoll()
            }
            .controlSize(.mini)
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 40)
        .padding(.top, 4)
    }

    // MARK: - Step 1: Model

    private var modelStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "cpu")
                .font(.system(size: 32))
                .foregroundStyle(.purple)

            Text("Download a Model")
                .font(.headline)

            Text("Start with Tiny for a quick setup.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if appState.modelManager.isDownloading {
                VStack(spacing: 6) {
                    ProgressView(value: appState.modelManager.downloadProgress)
                        .frame(width: 200)
                    Text("\(Int(appState.modelManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !appState.modelManager.availableLocalModels().isEmpty {
                Label("Model ready!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Download Tiny (~75 MB)") {
                    startTinyDownload()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, 12)
        .onAppear {
            // Auto-start download if no models exist
            if !autoDownloadStarted && appState.modelManager.availableLocalModels().isEmpty && !appState.modelManager.isDownloading {
                autoDownloadStarted = true
                startTinyDownload()
            }
        }
    }

    private func startTinyDownload() {
        if let tiny = AppConstants.availableModels.first(where: { $0.id == "tiny" }) {
            Task {
                try? await appState.modelManager.downloadModel(tiny)
                appState.settingsManager.selectedModelId = tiny.id
                await appState.loadSelectedModel()
            }
        }
    }

    // MARK: - Step 2: Ready

    private var readyStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 32))
                .foregroundStyle(.green)

            Text("Ready!")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                instructionStep("1", "Hold Option + Space")
                instructionStep("2", "Speak naturally")
                instructionStep("3", "Release to transcribe")
            }
        }
        .padding(.top, 12)
    }

    private func instructionStep(_ num: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(num)
                .font(.caption.weight(.bold))
                .frame(width: 22, height: 22)
                .background(.blue.opacity(0.15))
                .clipShape(Circle())
            Text(text).font(.callout)
        }
    }
}
