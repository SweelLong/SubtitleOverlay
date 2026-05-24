import Combine
import SwiftUI

enum RecognitionEngine: String, CaseIterable {
    case appleSpeech = "apple"
    case whisper = "whisper"

    var displayName: String {
        switch self {
        case .appleSpeech: return String(localized: "Apple Speech (On-Device)")
        case .whisper: return String(localized: "Whisper (Custom Model)")
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("showChineseTranslation") var showChineseTranslation = false
    @AppStorage("subtitleFontSize") var subtitleFontSize: Double = 20
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.45
    @AppStorage("windowWidth") var windowWidth: Double = 600
    @AppStorage("maxHistoryLines") var maxHistoryLines: Int = 3
    @AppStorage("selectedAppBundleID") var selectedAppBundleID: String = ""

    // Language
    @AppStorage("appLanguage") var appLanguageRaw: String = AppLanguage.system.rawValue

    var appLanguage: AppLanguage {
        get { AppLanguage(rawValue: appLanguageRaw) ?? .system }
        set { appLanguageRaw = newValue.rawValue }
    }

    // Model engine
    @AppStorage("recognitionEngine") var recognitionEngineRaw: String = RecognitionEngine.appleSpeech.rawValue

    var recognitionEngine: RecognitionEngine {
        get { RecognitionEngine(rawValue: recognitionEngineRaw) ?? .appleSpeech }
        set { recognitionEngineRaw = newValue.rawValue }
    }

    // Whisper model path
    @AppStorage("whisperModelPath") var whisperModelPath: String = ""

    // Recognition language locale (e.g. "en-US", "ja-JP")
    @AppStorage("recognitionLocale") var recognitionLocale: String = "en-US"

    // Translation target language code (e.g. "zh-Hans", "ja")
    @AppStorage("translationTarget") var translationTarget: String = "zh-Hans"

    var recognitionLanguage: RecognitionLanguage {
        RecognitionLanguage.find(recognitionLocale)
    }

    var translationTargetLanguage: TranslationTarget {
        TranslationTarget.find(translationTarget)
    }

    private init() {}
}
