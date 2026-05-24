import SwiftUI
import Combine

struct SubtitlePanelView: View {
    @ObservedObject private var speech = SpeechRecognizer.shared
    @ObservedObject private var translator = TranslationService.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var history: [String] = []
    @State private var prevNonEmpty: String = ""

    var body: some View {
        VStack(spacing: 6) {
            ForEach(history, id: \.self) { line in
                Text(line)
                    .font(.system(size: settings.subtitleFontSize * 0.85))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Text(currentText)
                .font(.system(size: settings.subtitleFontSize, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)

            if settings.showChineseTranslation, !translator.translatedText.isEmpty {
                Text(translator.translatedText)
                    .font(.system(size: settings.subtitleFontSize * 0.7))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minWidth: 300, idealWidth: settings.windowWidth, maxWidth: 900)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(settings.backgroundOpacity))
        )
        .onReceive(speech.$recognizedText) { text in
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                // Speech reset — archive what we had
                if !prevNonEmpty.isEmpty {
                    history.append(prevNonEmpty)
                    let cap = max(settings.maxHistoryLines - 1, 0)
                    if history.count > cap {
                        history.removeFirst(history.count - cap)
                    }
                    prevNonEmpty = ""
                }
            } else {
                prevNonEmpty = trimmed
            }
        }
    }

    private var currentText: String {
        let t = speech.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? " " : t
    }
}
