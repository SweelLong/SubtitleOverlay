import Foundation

/// A recognition language option for the speech-to-text engine.
struct RecognitionLanguage: Identifiable, Hashable {
    let id: String       // locale identifier, e.g. "en-US"
    let displayName: String

    static let all: [RecognitionLanguage] = [
        RecognitionLanguage(id: "en-US", displayName: "English (US)"),
        RecognitionLanguage(id: "en-GB", displayName: "English (UK)"),
        RecognitionLanguage(id: "zh-CN", displayName: "中文（普通话）"),
        RecognitionLanguage(id: "zh-HK", displayName: "中文（粤语）"),
        RecognitionLanguage(id: "ja-JP", displayName: "日本語"),
        RecognitionLanguage(id: "ko-KR", displayName: "한국어"),
        RecognitionLanguage(id: "fr-FR", displayName: "Français"),
        RecognitionLanguage(id: "de-DE", displayName: "Deutsch"),
        RecognitionLanguage(id: "es-ES", displayName: "Español"),
        RecognitionLanguage(id: "pt-BR", displayName: "Português (BR)"),
        RecognitionLanguage(id: "ru-RU", displayName: "Русский"),
        RecognitionLanguage(id: "it-IT", displayName: "Italiano"),
        RecognitionLanguage(id: "nl-NL", displayName: "Nederlands"),
        RecognitionLanguage(id: "ar-SA", displayName: "العربية"),
    ]

    /// Find by locale ID, falls back to en-US.
    static func find(_ id: String) -> RecognitionLanguage {
        all.first(where: { $0.id == id }) ?? all.first!
    }
}

/// A translation target language option.
struct TranslationTarget: Identifiable, Hashable {
    let id: String       // BCP-47 language code, e.g. "zh-Hans"
    let displayName: String

    static let all: [TranslationTarget] = [
        TranslationTarget(id: "zh-Hans", displayName: "中文（简体）"),
        TranslationTarget(id: "zh-Hant", displayName: "中文（繁体）"),
        TranslationTarget(id: "ja", displayName: "日本語"),
        TranslationTarget(id: "ko", displayName: "한국어"),
        TranslationTarget(id: "fr", displayName: "Français"),
        TranslationTarget(id: "de", displayName: "Deutsch"),
        TranslationTarget(id: "es", displayName: "Español"),
        TranslationTarget(id: "pt", displayName: "Português"),
        TranslationTarget(id: "ru", displayName: "Русский"),
        TranslationTarget(id: "it", displayName: "Italiano"),
        TranslationTarget(id: "nl", displayName: "Nederlands"),
        TranslationTarget(id: "ar", displayName: "العربية"),
        TranslationTarget(id: "th", displayName: "ไทย"),
        TranslationTarget(id: "vi", displayName: "Tiếng Việt"),
        TranslationTarget(id: "pl", displayName: "Polski"),
        TranslationTarget(id: "tr", displayName: "Türkçe"),
        TranslationTarget(id: "id", displayName: "Bahasa Indonesia"),
    ]

    static func find(_ id: String) -> TranslationTarget {
        all.first(where: { $0.id == id }) ?? all.first!
    }
}
