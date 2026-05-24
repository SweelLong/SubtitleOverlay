import Combine
import AVFoundation
// whisper.cpp integration:
//   1. In Xcode: File → Add Package Dependencies → https://github.com/ggerganov/whisper.spm
//   2. Uncomment: import whisper
//   3. Uncomment the implementation blocks in start() and processChunk()
//   4. Place a GGML model (e.g. ggml-base.en.bin) in ~/Library/Application Support/SubtitleOverlay/Models/

final class WhisperRecognizer: NSObject, ObservableObject, @unchecked Sendable {

    static let shared = WhisperRecognizer()

    @Published var modelStatus: ModelStatus = .noModel
    @Published var segments: [SubtitleSegment] = []
    @Published var recognizedText: String = ""

    enum ModelStatus {
        case noModel, loading, ready, error

        var localizedName: String {
            switch self {
            case .noModel: return String(localized: "No model loaded")
            case .loading: return String(localized: "Loading model...")
            case .ready: return String(localized: "Ready")
            case .error: return String(localized: "Error")
            }
        }
    }

    private var ctx: OpaquePointer?
    private var isRunning = false
    private let audioQueue = DispatchQueue(label: "whisper.audio", qos: .userInteractive)
    private let processQueue = DispatchQueue(label: "whisper.process", qos: .userInteractive)

    private var sampleBuffer: [Float] = []
    private let sampleRate: Double = 16000
    private var lastProcessTime: Date = .distantPast
    private let minProcessInterval: TimeInterval = 0.5

    private override init() {
        super.init()
        checkModel()
    }

    // MARK: - Model Management

    func importModel(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        guard ext == "ggml" || ext == "bin" else {
            modelStatus = .error
            return false
        }

        modelStatus = .loading

        let dest = modelDirectory().appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.createDirectory(at: modelDirectory(),
                                                  withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: url, to: dest)
            AppSettings.shared.whisperModelPath = dest.path
            modelStatus = .ready
            modelLoaded = true
            return true
        } catch {
            modelStatus = .error
            return false
        }
    }

    func removeModel() {
        if let path = AppSettings.shared.whisperModelPath.isEmpty
            ? nil : AppSettings.shared.whisperModelPath,
           FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        AppSettings.shared.whisperModelPath = ""
        modelLoaded = false
        modelStatus = .noModel
        ctx = nil
    }

    private func checkModel() {
        let path = AppSettings.shared.whisperModelPath
        if !path.isEmpty, FileManager.default.fileExists(atPath: path) {
            modelLoaded = true
            modelStatus = .ready
        } else {
            modelStatus = .noModel
        }
    }

    func modelDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("SubtitleOverlay/Models")
    }

    // MARK: - Recognition

    var modelLoaded = false

    func start() throws {
        guard modelLoaded else { throw WhisperError.noModel }

        guard let path = AppSettings.shared.whisperModelPath.isEmpty
                ? nil : AppSettings.shared.whisperModelPath,
              FileManager.default.fileExists(atPath: path) else {
            modelStatus = .error
            throw WhisperError.noModel
        }

        // --- Uncomment when whisper.spm is linked: ---
        // modelStatus = .loading
        // let result = path.withCString { whisper_init_from_file($0) }
        // guard let context = result else { modelStatus = .error; throw WhisperError.failedToLoadModel }
        // ctx = context
        // isRunning = true
        // sampleBuffer = []
        // lastProcessTime = .distantPast
        // modelStatus = .ready
    }

    func stop() {
        isRunning = false
        // whisper_free(ctx); ctx = nil
        sampleBuffer = []
    }

    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isRunning, modelLoaded, ctx != nil else { return }

        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        audioQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.sampleBuffer.append(contentsOf: samples)

            let processThreshold = Int(self.sampleRate * self.minProcessInterval)
            let now = Date()
            if self.sampleBuffer.count >= processThreshold,
               now.timeIntervalSince(self.lastProcessTime) >= self.minProcessInterval {
                self.lastProcessTime = now
                let chunk = self.sampleBuffer
                self.sampleBuffer = []
                self.processChunk(chunk)
            }
        }
    }

    private func processChunk(_ samples: [Float]) {
        guard ctx != nil, isRunning else { return }

        processQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            // --- Uncomment when whisper.spm is linked: ---
            // var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            // params.print_progress = false
            // params.print_realtime = false
            // params.print_special = false
            // params.language = "en".cString(using: .utf8)?.withUnsafeBufferPointer { $0.baseAddress }
            // params.n_threads = min(4, Int32(ProcessInfo.processInfo.activeProcessorCount))
            // params.single_segment = true
            // let result = samples.withUnsafeBufferPointer { ptr in
            //     whisper_full(ctx, params, ptr.baseAddress, Int32(samples.count))
            // }
            // guard result == 0 else { return }
            // let nSegments = whisper_full_n_segments(ctx)
            // var textParts: [String] = []
            // for i in 0..<nSegments {
            //     if let cText = whisper_full_get_segment_text(ctx, i) {
            //         textParts.append(String(cString: cText))
            //     }
            // }
            // let text = textParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            // guard !text.isEmpty else { return }
            // DispatchQueue.main.async {
            //     self.recognizedText = text
            //     self.segments = [SubtitleSegment(text: text, isFinal: true)]
            // }
        }
    }
}

enum WhisperError: LocalizedError {
    case noModel
    case failedToLoadModel

    var errorDescription: String? {
        switch self {
        case .noModel:
            return String(localized: "No Whisper model loaded. Import a GGML model file first.")
        case .failedToLoadModel:
            return String(localized: "Failed to load Whisper model. The file may be corrupted or incompatible.")
        }
    }
}
