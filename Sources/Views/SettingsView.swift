import SwiftUI

struct SettingsView: View {
    let appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("General", icon: "gear", tag: 0)
                tabButton("Models", icon: "cpu", tag: 1)
                tabButton("Advanced", icon: "slider.horizontal.3", tag: 2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Divider().padding(.top, 8)

            // Content
            Group {
                switch selectedTab {
                case 0: GeneralTab(appState: appState)
                case 1: ModelPickerView(appState: appState)
                case 2: AdvancedTab(appState: appState)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480, height: 380)
    }

    private func tabButton(_ title: String, icon: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selectedTab == tag ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedTab == tag ? .primary : .secondary)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    let appState: AppState
    @State private var isLoadingModel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Hotkey
            LabeledContent("Toggle recording") {
                HotkeyRecorderView(hotKeyManager: appState.hotKeyManager)
            }

            Divider()

            // Language
            LabeledContent("Language") {
                HStack(spacing: 8) {
                    Picker("", selection: Binding(
                        get: { appState.settingsManager.language },
                        set: { newValue in
                            appState.settingsManager.language = newValue
                            isLoadingModel = true
                            Task {
                                await appState.loadSelectedModel()
                                isLoadingModel = false
                            }
                        }
                    )) {
                        Text("English").tag("en")
                        Text("Auto-detect").tag("auto")
                        Text("Spanish").tag("es")
                        Text("French").tag("fr")
                        Text("German").tag("de")
                        Text("Japanese").tag("ja")
                        Text("Chinese").tag("zh")
                    }
                    .frame(width: 140)

                    if isLoadingModel {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }

            Divider()

            // Toggles
            Toggle("Launch at login", isOn: Binding(
                get: { appState.launchAtLoginManager.isEnabled },
                set: { appState.launchAtLoginManager.setEnabled($0) }
            ))

            Toggle("Sound feedback", isOn: Binding(
                get: { appState.settingsManager.soundFeedback },
                set: { appState.settingsManager.soundFeedback = $0 }
            ))

            Toggle("Keep transcription in clipboard", isOn: Binding(
                get: { appState.settingsManager.keepInClipboard },
                set: { appState.settingsManager.keepInClipboard = $0 }
            ))

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Advanced Tab

private struct AdvancedTab: View {
    let appState: AppState
    @State private var promptText: String = ""
    @State private var vocabularyText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Custom Vocabulary")
                    .font(.headline)

                TextField("Kubernetes, FastAPI, Anthropic", text: $vocabularyText)
                    .textFieldStyle(.roundedBorder)

                Text("Comma-separated words the model should recognize (names, brands, technical terms).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Text("Initial Prompt")
                    .font(.headline)

                TextEditor(text: $promptText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 80)
                    .border(.quaternary)

                Text("Guide the model's style — punctuation, formatting, or domain-specific terms.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                // Permissions section
                Text("Permissions")
                    .font(.headline)

                PermissionRow(
                    icon: appState.permissionManager.microphoneAuthorized ? "mic.fill" : "mic.slash",
                    title: "Microphone",
                    granted: appState.permissionManager.microphoneAuthorized,
                    grantAction: { Task { await appState.permissionManager.requestMicrophoneAccess() } }
                )

                PermissionRow(
                    icon: appState.permissionManager.accessibilityAuthorized ? "lock.open.fill" : "lock.shield",
                    title: "Accessibility",
                    granted: appState.permissionManager.accessibilityAuthorized,
                    grantAction: { appState.permissionManager.openAccessibilitySettings() },
                    buttonLabel: "Open Settings"
                )

                if !appState.permissionManager.accessibilityAuthorized {
                    Text("System Settings > Privacy & Security > Accessibility > Enable WhisperDictation")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .italic()
                        .padding(.leading, 34)
                }

                Divider()

                // Reset onboarding
                Button("Reset Onboarding") {
                    UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
                    WindowManager.shared.openOnboarding(appState: appState)
                }
                .controlSize(.small)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .onAppear {
            promptText = appState.settingsManager.initialPrompt
            vocabularyText = appState.settingsManager.customVocabulary
        }
        .onChange(of: promptText) { _, newValue in
            appState.settingsManager.initialPrompt = newValue
            appState.whisperManager.setPrompt(newValue, vocabulary: appState.settingsManager.customVocabulary)
        }
        .onChange(of: vocabularyText) { _, newValue in
            appState.settingsManager.customVocabulary = newValue
            appState.whisperManager.setPrompt(appState.settingsManager.initialPrompt, vocabulary: newValue)
        }
    }
}

// MARK: - Permission Row (reusable)

private struct PermissionRow: View {
    let icon: String
    let title: String
    let granted: Bool
    let grantAction: () -> Void
    var buttonLabel: String = "Grant"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(granted ? .green : .orange)
                .frame(width: 20)
            Text(title)
                .font(.callout)
            Spacer()
            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(buttonLabel) { grantAction() }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
            }
        }
    }
}
