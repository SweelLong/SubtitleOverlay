import Combine
import Speech
import AVFoundation
import AppKit

final class SpeechRecognizer: NSObject, ObservableObject, @unchecked Sendable {

    static let shared = SpeechRecognizer()

    @Published var recognizedText: String = ""
    @Published var isAvailable: Bool = false
    @Published var modelStatus: ModelStatus = .checking
    @Published var segments: [SubtitleSegment] = []

    enum ModelStatus {
        case checking, downloading, ready, unavailable, error

        var localizedName: String {
            switch self {
            case .checking: return String(localized: "Checking...")
            case .downloading: return String(localized: "Downloading model...")
            case .ready: return String(localized: "Ready")
            case .unavailable: return String(localized: "Unavailable")
            case .error: return String(localized: "Error")
            }
        }
    }

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var currentLocale: String = ""

    private override init() {
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        let localeId = AppSettings.shared.recognitionLocale
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
        recognizer?.delegate = self
        currentLocale = localeId
        checkAvailability()
    }

    /// Re-initialize with a new locale (called when user changes recognition language).
    func switchLocale(_ localeId: String) {
        guard localeId != currentLocale else { return }
        stop()
        AppSettings.shared.recognitionLocale = localeId
        setupRecognizer()
    }

    private func checkAvailability() {
        guard let r = recognizer else {
            isAvailable = false
            modelStatus = .unavailable
            return
        }
        r.supportsOnDeviceRecognition = true

        if r.isAvailable {
            // Check if on-device model is actually downloaded.
            if r.supportsOnDeviceRecognition {
                modelStatus = .ready
            } else {
                modelStatus = .downloading
            }
            isAvailable = true
        } else {
            modelStatus = .downloading
            isAvailable = false
        }
    }

    func start() throws {
        // Re-setup if locale changed since last init
        let targetLocale = AppSettings.shared.recognitionLocale
        if targetLocale != currentLocale {
            setupRecognizer()
        }

        guard let recognizer, recognizer.isAvailable else {
            modelStatus = .error
            throw RecognizerError.unavailable
        }

        stop()

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.requiresOnDeviceRecognition = true
        request?.shouldReportPartialResults = true
        request?.addsPunctuation = true
        request?.taskHint = .search

        modelStatus = .ready

        task = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            guard let self else { return }

            if let error {
                print("[SubtitleOverlay] Speech error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.modelStatus = .error
                }
                return
            }

            guard let result else { return }
            let text = result.bestTranscription.formattedString

            DispatchQueue.main.async {
                self.recognizedText = text

                var newSegments: [SubtitleSegment] = []
                for seg in result.bestTranscription.segments where seg.confidence > 0.2 {
                    newSegments.append(SubtitleSegment(
                        text: seg.substring,
                        isFinal: true
                    ))
                }
                if !newSegments.isEmpty {
                    self.segments = newSegments
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func openSpeechSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")!)
    }
}

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        isAvailable = available
        modelStatus = available ? .ready : .downloading
    }
}

enum RecognizerError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        String(localized: "On-device speech recognition unavailable. Check System Settings > Privacy & Security > Speech Recognition. The speech model for your selected language must be downloaded.")
    }
}

struct SubtitleSegment: Identifiable {
    let id = UUID()
    let text: String
    let isFinal: Bool
}
