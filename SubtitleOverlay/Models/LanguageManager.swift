import SwiftUI

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"

    var displayName: String {
        switch self {
        case .system: return String(localized: "System Default")
        case .english: return String(localized: "English")
        case .chinese: return String(localized: "中文")
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .chinese: return "zh-Hans"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") var selectedLanguage: AppLanguage = .system
    @Published var needsRestart = false

    private init() {}

    func apply() {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        let lang = AppLanguage(rawValue: raw) ?? .system
        selectedLanguage = lang

        if let locale = lang.localeIdentifier {
            UserDefaults.standard.set([locale], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()

        needsRestart = true
    }

    func relaunch() {
        let task = Process()
        task.executableURL = Bundle.main.executableURL
        try? task.run()
        NSApp.terminate(nil)
    }
}
