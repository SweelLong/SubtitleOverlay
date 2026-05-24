import Combine
import Translation
import AppKit

@MainActor
final class TranslationService: ObservableObject {
    static let shared = TranslationService()

    @Published var translatedText: String = ""
    @Published var isReady: Bool = false
    @Published var statusMessage: String = ""

    private var session: TranslationSession?
    private var latestTask: Task<Void, Never>?
    private var currentSourceId: String = ""
    private var currentTargetId: String = ""

    private init() {
        if #available(macOS 15.0, *) {
            Task { await setup() }
        }
    }

    /// Source language maps from recognition locale (first component).
    private var sourceId: String {
        let locale = AppSettings.shared.recognitionLocale // e.g. "en-US"
        return String(locale.split(separator: "-").first ?? "en")
    }

    private var targetId: String {
        AppSettings.shared.translationTarget
    }

    private func setup() async {
        let src = sourceId
        let tgt = targetId
        currentSourceId = src
        currentTargetId = tgt

        let source = Locale.Language(identifier: src)
        let target = Locale.Language(identifier: tgt)

        let availability = LanguageAvailability()
        let pairStatus = await availability.status(from: source, to: target)
        print("[SubtitleOverlay] Translation \(src)→\(tgt) status: \(pairStatus)")

        if pairStatus == .unsupported {
            isReady = false
            statusMessage = String(format: String(localized: "%1$@→%2$@ translation not supported on this device."), src, tgt)
            return
        }

        let s = TranslationSession(installedSource: source, target: target)
        self.session = s

        do {
            try await s.prepareTranslation()
            isReady = true
            statusMessage = ""
            print("[SubtitleOverlay] Translation models installed and ready (\(src)→\(tgt)).")
        } catch {
            print("[SubtitleOverlay] prepareTranslation: \(error)")
            isReady = false
            let srcName = RecognitionLanguage.find(AppSettings.shared.recognitionLocale).displayName
            let tgtName = TranslationTarget.find(tgt).displayName
            statusMessage = String(format: String(localized: "Translation models not installed. Open System Settings → General → Language & Region → scroll to bottom → \"Translation Languages\" → download both \"%1$@\" and \"%2$@\"."), srcName, tgtName)
        }
    }

    func refreshStatus() async {
        await setup()
    }

    /// Call when user changes recognition language or translation target.
    func switchLanguages() {
        Task {
            stopTranslation()
            await setup()
        }
    }

    private func stopTranslation() {
        latestTask?.cancel()
        latestTask = nil
        session = nil
        translatedText = ""
    }

    func openLanguageSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension")!)
    }

    func translate(_ text: String) {
        // Re-setup if languages changed
        let src = sourceId
        let tgt = targetId
        if src != currentSourceId || tgt != currentTargetId {
            Task {
                stopTranslation()
                await setup()
            }
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            translatedText = ""
            return
        }

        if session == nil {
            Task { await setup() }
            return
        }

        latestTask?.cancel()
        latestTask = Task { [weak self] in
            guard let self, let session = self.session else { return }

            do {
                let response = try await session.translate(trimmed)
                guard !Task.isCancelled else { return }
                let result = response.targetText
                if !result.isEmpty {
                    self.translatedText = result
                    if !self.isReady {
                        self.isReady = true
                        self.statusMessage = ""
                    }
                }
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                print("[SubtitleOverlay] Translation failed: \(error)")
                self.isReady = false
            }
        }
    }
}
