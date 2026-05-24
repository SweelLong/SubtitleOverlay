import SwiftUI
import ScreenCaptureKit

struct ContentView: View {
    @StateObject private var captureManager = AudioCaptureManager()
    @ObservedObject private var speech = SpeechRecognizer.shared
    @ObservedObject private var translator = TranslationService.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var availableApps: [SCRunningApplication] = []
    @State private var availableDisplays: [SCDisplay] = []
    @State private var selectedApp: SCRunningApplication?
    @State private var selectedDisplay: SCDisplay?
    @State private var permissionDenied = false
    @State private var errorMessage: String?

    private let windowController = SubtitleWindowController()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    permissionWarning
                    modelStatusSection
                    appPicker
                    actionButtons
                    errorSection
                    livePreview
                }
                .padding()
            }
        }
        .frame(width: 420, height: 480)
        .task { await loadContent() }
    }

    // MARK: - Header

    private struct HeaderView: View {
        var body: some View {
            HStack {
                Image(systemName: "captions.bubble")
                    .font(.title2)
                Text("Subtitle Overlay")
                    .font(.title3.weight(.semibold))
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    // MARK: - Permission Warning

    @ViewBuilder
    private var permissionWarning: some View {
        if permissionDenied {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Screen Recording permission required. Click below to trigger the system permission dialog, then grant access.")
                        .font(.callout)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }

                Button {
                    Task { await loadContent() }
                } label: {
                    Label("Request Permission", systemImage: "lock.shield")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(12)
            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Model Status

    private var modelStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let recogName = settings.recognitionLanguage.displayName
            let transName = settings.translationTargetLanguage.displayName

            Text(String(format: String(localized: "%@ Recognition"), recogName))
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Circle()
                    .fill(modelStatusColor)
                    .frame(width: 8, height: 8)
                Text(speech.modelStatus.localizedName)
                    .font(.callout)
                Spacer()
                if speech.modelStatus == .ready {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .help(LocalizedStringKey("On-device recognition active — no internet needed"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            // Translation model status
            HStack(spacing: 10) {
                Circle()
                    .fill(translator.isReady ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                if translator.isReady {
                    Text(String(format: String(localized: "%@ Translation: Ready"), transName))
                        .font(.callout)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(format: String(localized: "%@ Translation: Models not installed"), transName))
                            .font(.callout)

                        if !translator.statusMessage.isEmpty {
                            Text(translator.statusMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 8) {
                            Button {
                                translator.openLanguageSettings()
                            } label: {
                                Label("Open Translation Settings", systemImage: "gearshape")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button {
                                Task { await translator.refreshStatus() }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var modelStatusColor: Color {
        switch speech.modelStatus {
        case .ready: return .green
        case .checking, .downloading: return .yellow
        case .unavailable, .error: return .red
        }
    }

    // MARK: - App Picker

    private var appPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Capture audio from")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Picker("Application", selection: $selectedApp) {
                Text("Select an app…").tag(nil as SCRunningApplication?)
                ForEach(availableApps, id: \.bundleIdentifier) { app in
                    Text(app.appName).tag(app as SCRunningApplication?)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .onChange(of: selectedApp) { old, new in updateSelection() }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                windowController.toggle()
            } label: {
                Label("Show Overlay", systemImage: "rectangle.topthird.inset")
            }
            .buttonStyle(.bordered)

            Button {
                captureManager.isCapturing ? stopCapture() : startCapture()
            } label: {
                Label(
                    captureManager.isCapturing ? "Stop" : "Start",
                    systemImage: captureManager.isCapturing ? "stop.fill" : "play.fill"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedApp == nil)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .padding(10)
                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Live Preview

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live Preview")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)

            Text(speech.recognizedText.isEmpty
                 ? LocalizedStringKey("(waiting for speech…)")
                 : LocalizedStringKey(speech.recognizedText))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(speech.recognizedText.isEmpty ? .secondary : .primary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            if settings.showChineseTranslation, !translator.translatedText.isEmpty {
                Text(translator.translatedText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .onReceive(speech.$recognizedText) { text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if settings.showChineseTranslation, !trimmed.isEmpty {
                translator.translate(trimmed)
            }
        }
    }

    // MARK: - Status Indicators (compact)

    private var statusIndicatorsCompact: some View {
        HStack(spacing: 16) {
            dot("Capture", active: captureManager.isCapturing, color: .green)
            dot("Speech", active: speech.isAvailable, color: .blue)
        }
        .padding(.top, 4)
    }

    private func dot(_ label: String, active: Bool, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(active ? color : .gray.opacity(0.4)).frame(width: 7, height: 7)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func loadContent() async {
        do {
            let content = try await captureManager.fetchShareableContent()
            availableApps = content.applications
            availableDisplays = content.displays
            permissionDenied = false

            let saved = settings.selectedAppBundleID
            if !saved.isEmpty,
               let app = availableApps.first(where: { $0.bundleIdentifier == saved }) {
                selectedApp = app
            }
            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
        } catch {
            permissionDenied = true
        }
    }

    private func updateSelection() {
        if let app = selectedApp {
            settings.selectedAppBundleID = app.bundleIdentifier
        }
    }

    private func startCapture() {
        guard let app = selectedApp, let display = selectedDisplay else { return }

        errorMessage = nil
        do {
            try speech.start()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        captureManager.onBuffer = { buffer in
            SpeechRecognizer.shared.appendAudioBuffer(buffer)
        }
        captureManager.onError = { error in
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }

        Task {
            do {
                let content = try await captureManager.fetchShareableContent()
                let windows = content.windows.filter {
                    $0.owningApplication?.bundleIdentifier == app.bundleIdentifier
                }
                try await captureManager.startCapture(
                    app: app,
                    display: display,
                    windows: windows
                )
                windowController.show()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func stopCapture() {
        captureManager.stopCapture()
        speech.stop()
    }
}

private extension SCRunningApplication {
    var appName: String { applicationName }
}
