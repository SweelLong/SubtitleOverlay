import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var speech = SpeechRecognizer.shared
    @ObservedObject private var translator = TranslationService.shared
    @ObservedObject private var whisper = WhisperRecognizer.shared
    @ObservedObject private var lang = LanguageManager.shared

    @State private var showModelPicker = false

    var body: some View {
        TabView {
            displayTab
                .tabItem { Label("Display", systemImage: "textformat") }

            modelTab
                .tabItem { Label("Model", systemImage: "brain") }

            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 520)
    }

    // MARK: - Display Tab

    private var displayTab: some View {
        Form {
            Section {
                Toggle("Show Chinese Translation", isOn: $settings.showChineseTranslation)
                    .help("Smaller Chinese text shown below English subtitles.")

                Picker("UI Language", selection: Binding(
                    get: { settings.appLanguage },
                    set: { newLang in
                        settings.appLanguage = newLang
                        LanguageManager.shared.apply()
                    }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .help("App interface language. Requires app restart to take full effect.")

                if lang.needsRestart {
                    HStack {
                        Label(String(localized: "Language changed — restart to apply."), systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                        Spacer()
                        Button(String(localized: "Restart Now")) {
                            LanguageManager.shared.relaunch()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            } header: {
                Text("Language & Translation")
            }

            Section {
                HStack {
                    Text("Font Size")
                    Slider(value: $settings.subtitleFontSize, in: 14...36, step: 2)
                    Text(verbatim: String(Int(settings.subtitleFontSize)) + "pt")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Background")
                    Slider(value: $settings.backgroundOpacity, in: 0.1...0.9, step: 0.05)
                    Text(verbatim: String(Int(settings.backgroundOpacity * 100)) + "%")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("History Lines")
                    Slider(value: Binding(
                        get: { Double(settings.maxHistoryLines) },
                        set: { settings.maxHistoryLines = Int($0) }
                    ), in: 1...5, step: 1)
                    Text("\(settings.maxHistoryLines)")
                        .frame(width: 20, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Appearance")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Model Tab

    private var modelTab: some View {
        Form {
            Section {
                Picker("Recognition Engine", selection: Binding(
                    get: { settings.recognitionEngine },
                    set: { settings.recognitionEngine = $0 }
                )) {
                    ForEach(RecognitionEngine.allCases, id: \.self) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
            } header: {
                Text("Engine")
            }

            // Language selectors — always visible when using Apple Speech
            if settings.recognitionEngine == .appleSpeech {
                Section {
                    Picker("Recognition Language", selection: Binding(
                        get: { settings.recognitionLocale },
                        set: { newLocale in
                            settings.recognitionLocale = newLocale
                            speech.switchLocale(newLocale)
                            translator.switchLanguages()
                        }
                    )) {
                        ForEach(RecognitionLanguage.all) { lang in
                            Text(lang.displayName).tag(lang.id)
                        }
                    }

                    Picker("Translate To", selection: Binding(
                        get: { settings.translationTarget },
                        set: { newTarget in
                            settings.translationTarget = newTarget
                            translator.switchLanguages()
                        }
                    )) {
                        ForEach(TranslationTarget.all) { lang in
                            Text(lang.displayName).tag(lang.id)
                        }
                    }
                } header: {
                    Text("Language Configuration")
                }
            }

            // Status section
            if settings.recognitionEngine == .appleSpeech {
                Section {
                    HStack {
                        Text(String(format: String(localized: "%@ Recognition"), settings.recognitionLanguage.displayName))
                        Spacer()
                        appleModelBadge(speech.modelStatus)
                    }

                    HStack {
                        let srcAbbr = settings.recognitionLanguage.displayName.split(separator: " ").first.map(String.init) ?? "EN"
                        let tgtName = settings.translationTargetLanguage.displayName
                        Text(String(format: String(localized: "%1$@ → %2$@ Translation"), srcAbbr, tgtName))
                        Spacer()
                        if translator.isReady {
                            Label("Ready", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Not Installed", systemImage: "xmark.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    if !translator.isReady {
                        VStack(alignment: .leading, spacing: 8) {
                            if !translator.statusMessage.isEmpty {
                                Text(translator.statusMessage)
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Button {
                                    translator.openLanguageSettings()
                                } label: {
                                    Label("Open Translation Settings", systemImage: "gearshape")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)

                                Button {
                                    Task { await translator.refreshStatus() }
                                } label: {
                                    Label("Refresh Status", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Model Status")
                }

                Section {
                    Text("On-device models managed by macOS. All processing uses Apple Neural Engine — no data leaves your Mac.")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button {
                        speech.openSpeechSettings()
                    } label: {
                        Label("Manage Speech Models in System Settings", systemImage: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } header: {
                    Text("Privacy")
                }
            }

            // Whisper model management
            if settings.recognitionEngine == .whisper {
                Section {
                    HStack {
                        Text("Model File")
                        Spacer()
                        Text(currentModelName)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        whisperModelBadge(whisper.modelStatus)
                    }
                } header: {
                    Text("Whisper Model")
                }

                Section {
                    Button {
                        showModelPicker = true
                    } label: {
                        Label("Import GGML Model...", systemImage: "plus.circle")
                    }
                    .fileImporter(
                        isPresented: $showModelPicker,
                        allowedContentTypes: [UTType(filenameExtension: "ggml") ?? .data,
                                              UTType(filenameExtension: "bin") ?? .data],
                        allowsMultipleSelection: false
                    ) { result in
                        if case .success(let urls) = result, let url = urls.first {
                            _ = whisper.importModel(url: url)
                        }
                    }

                    if !settings.whisperModelPath.isEmpty {
                        Button(role: .destructive) {
                            whisper.removeModel()
                        } label: {
                            Label("Remove Model", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Model Management")
                }

                Section {
                    Text("Whisper models can be downloaded from HuggingFace (ggerganov/whisper.cpp).\nRecommended: ggml-tiny.en.bin or ggml-base.en.bin for real-time use.\n\nTo integrate whisper.cpp: add package https://github.com/ggerganov/whisper.cpp in Xcode → File → Add Package Dependencies.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Setup Guide")
                }
            }

            // Troubleshooting
            Section {
                Text("If speech recognition is unavailable, check System Settings > Privacy & Security > Screen Recording for audio capture permission, and verify the speech model for your selected language is downloaded.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Troubleshooting")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "captions.bubble.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("Subtitle Overlay")
                .font(.title.weight(.medium))

            Text("Real-time subtitles from system audio.\nOn-device speech recognition and translation.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Engines: Apple Speech (On-Device) | Whisper (Custom Model)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Powered by Apple Speech & Translation frameworks.\nAll processing stays on-device.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Version 1.0")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }

    // MARK: - Helpers

    private var currentModelName: String {
        let path = settings.whisperModelPath
        if path.isEmpty { return "None" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private func appleModelBadge(_ s: SpeechRecognizer.ModelStatus) -> some View {
        switch s {
        case .ready:
            Label("Ready", systemImage: "checkmark.circle.fill").foregroundColor(.green)
        case .checking:
            Label("Checking...", systemImage: "hourglass").foregroundColor(.yellow)
        case .downloading:
            Label("Downloading...", systemImage: "arrow.down.circle").foregroundColor(.yellow)
        case .unavailable:
            Label("Unavailable", systemImage: "xmark.circle.fill").foregroundColor(.red)
        case .error:
            Label("Error", systemImage: "exclamationmark.circle.fill").foregroundColor(.red)
        }
    }

    private func whisperModelBadge(_ s: WhisperRecognizer.ModelStatus) -> some View {
        switch s {
        case .ready:
            Label("Ready", systemImage: "checkmark.circle.fill").foregroundColor(.green)
        case .noModel:
            Label("No model", systemImage: "xmark.circle.fill").foregroundColor(.orange)
        case .loading:
            Label("Loading...", systemImage: "arrow.down.circle").foregroundColor(.yellow)
        case .error:
            Label("Error", systemImage: "exclamationmark.circle.fill").foregroundColor(.red)
        }
    }
}
