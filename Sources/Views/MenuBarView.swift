import SwiftUI

struct MenuBarView: View {
    let appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status header with model quick-switcher
            HStack(spacing: 8) {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(appState.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                modelBadge
            }

            if case .recording = appState.recordingState {
                RecordingIndicatorView()

                // Show live streaming transcription
                if appState.settingsManager.streamingMode && !appState.streamingTranscription.isEmpty {
                    Text(appState.streamingTranscription)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .italic()
                }
            }

            // Last transcription with copy button
            if !appState.lastTranscription.isEmpty {
                Divider()
                HStack(alignment: .top, spacing: 6) {
                    Text(appState.lastTranscription)
                        .font(.system(.body, design: .rounded))
                        .lineLimit(5)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appState.lastTranscription, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Permission banners
            if !appState.permissionManager.isFullyPermissioned {
                Divider()
                permissionBanner
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Settings") {
                    WindowManager.shared.openSettings(appState: appState)
                }
                .buttonStyle(.borderless)

                Spacer()

                // Hotkey badge
                Text(appState.hotKeyManager.currentHotkeyDescription)
                    .font(.system(.caption2, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 360)
    }

    // MARK: - Model Quick-Switcher

    private var modelBadge: some View {
        Menu {
            let localModels = appState.modelManager.availableLocalModels()
            if localModels.isEmpty {
                Text("No models downloaded")
            } else {
                ForEach(localModels) { model in
                    Button {
                        appState.settingsManager.selectedModelId = model.id
                        Task { await appState.loadSelectedModel() }
                    } label: {
                        HStack {
                            Text(model.name)
                            if appState.settingsManager.selectedModelId == model.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Manage Models...") {
                WindowManager.shared.openSettings(appState: appState)
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(appState.modelLoaded ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(appState.settingsManager.selectedModel?.id.capitalized ?? "None")
                    .font(.caption2.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary)
            .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
    }

    // MARK: - Permission Banners

    private var permissionBanner: some View {
        VStack(spacing: 6) {
            if !appState.permissionManager.microphoneAuthorized {
                permissionRow("Microphone access needed", icon: "mic.slash") {
                    Task { await appState.permissionManager.requestMicrophoneAccess() }
                }
            }
            if !appState.permissionManager.accessibilityAuthorized {
                permissionRow("Accessibility access needed", icon: "lock.shield") {
                    appState.permissionManager.requestAccessibilityAccess()
                }
            }
        }
    }

    private func permissionRow(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.orange)
                Text(text)
                    .font(.caption.weight(.medium))
                Spacer()
                Text("Fix")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(8)
            .background(.orange.opacity(0.08))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status

    private var statusIcon: some View {
        Group {
            switch appState.recordingState {
            case .idle:
                Image(systemName: appState.modelLoaded ? "waveform" : "waveform.badge.exclamationmark")
                    .foregroundStyle(appState.modelLoaded ? .green : .orange)
            case .recording:
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            case .transcribing:
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
            case .error:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
        .font(.title2)
    }

    private var statusTitle: String {
        switch appState.recordingState {
        case .idle:
            return appState.modelLoaded ? "Whisper Dictation" : "No Model Loaded"
        case .recording:
            return "Recording..."
        case .transcribing:
            return "Transcribing..."
        case .error(let msg):
            return "Error: \(msg)"
        }
    }
}
