import SwiftUI

struct MenuBarView: View {
    let appState: AppState

    private var streamingSelection: Binding<Int> {
        Binding(
            get: {
                appState.settingsManager.fastStreamingMode ? 1 : 0
            },
            set: { value in
                appState.settingsManager.fastStreamingMode = (value == 1)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status header with model quick-switcher
            HStack(spacing: 8) {
                statusIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.body.weight(.semibold))
                    Text(appState.statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                modelBadge
            }

            if case .recording = appState.recordingState {
                RecordingIndicatorView()
            }

            // Last transcription with copy button
            if !appState.lastTranscription.isEmpty {
                Divider()
                HStack(alignment: .top, spacing: 6) {
                    Text(appState.lastTranscription)
                        .font(.callout)
                        .lineLimit(5)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(appState.lastTranscription, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.callout)
                    }
                    .buttonStyle(.hover)
                }
            }

            // Permission banners
            if !appState.permissionManager.isFullyPermissioned {
                Divider()
                permissionBanner
            }

            Divider()

            // Streaming mode picker
            HStack(spacing: 8) {
                Text("Streaming:")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HoverSegmentedPicker(
                    selection: streamingSelection,
                    options: ["Off", "On"]
                )
            }

            Divider()

            // Footer
            HStack(spacing: 12) {
                Button("Settings") {
                    WindowManager.shared.openSettings(appState: appState)
                }
                .font(.callout)
                .buttonStyle(.hover)

                Spacer()

                // Hotkey badge
                Text(appState.hotKeyManager.currentHotkeyDescription)
                    .font(.system(.callout, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.callout)
                .buttonStyle(.hoverDestructive)
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
                    .font(.callout.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
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
        PermissionRowButton(text: text, icon: icon, action: action)
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

private struct PermissionRowButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.orange)
                    .font(.callout)
                Text(text)
                    .font(.callout.weight(.medium))
                Spacer()
                Text("Fix")
                    .font(.callout.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(isHovered ? 0.4 : 0.2))
                    .cornerRadius(4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.orange.opacity(isHovered ? 0.15 : 0.08))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
