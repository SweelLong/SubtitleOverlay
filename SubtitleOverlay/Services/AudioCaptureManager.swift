import Combine
import AVFoundation
import ScreenCaptureKit

final class AudioCaptureManager: NSObject, ObservableObject, @unchecked Sendable {

    private var stream: SCStream?
    private var streamOutput: StreamOutput?

    var onBuffer: ((AVAudioPCMBuffer) -> Void)?
    var onError: ((Error) -> Void)?

    private(set) var isCapturing = false

    func fetchShareableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    /// Start capturing audio from `app` on `display`.
    /// `windows` — all windows belonging to the target app on this display.
    func startCapture(app: SCRunningApplication, display: SCDisplay,
                      windows: [SCWindow]) async throws {
        stopCapture()

        let filter = SCContentFilter(
            display: display,
            including: windows
        )

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16000
        config.channelCount = 1
        config.queueDepth = 1

        let output = StreamOutput()
        output.onBuffer = { [weak self] in self?.onBuffer?($0) }
        output.onError = { [weak self] in self?.onError?($0) }
        self.streamOutput = output

        let scStream = SCStream(filter: filter, configuration: config, delegate: nil)
        let audioQueue = DispatchQueue(label: "audio.capture", qos: .userInteractive)
        try scStream.addStreamOutput(output, type: .audio, sampleHandlerQueue: audioQueue)
        self.stream = scStream

        try await scStream.startCapture()
        isCapturing = true
    }

    func stopCapture() {
        guard isCapturing else { return }
        stream?.stopCapture()
        stream = nil
        streamOutput = nil
        isCapturing = false
    }
}

// MARK: - Stream Output

private final class StreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {

    var onBuffer: ((AVAudioPCMBuffer) -> Void)?
    var onError: ((Error) -> Void)?

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let pcm = sampleBufferToPCM(sampleBuffer) else {
            onError?(CaptureError.bufferConversionFailed)
            return
        }
        onBuffer?(pcm)
    }

    private func sampleBufferToPCM(_ sbuf: CMSampleBuffer) -> AVAudioPCMBuffer? {
        guard let fmtDesc = CMSampleBufferGetFormatDescription(sbuf),
              CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc) != nil else {
            return nil
        }
        let audioFmt = AVAudioFormat(cmAudioFormatDescription: fmtDesc)

        let frameCount = CMSampleBufferGetNumSamples(sbuf)
        let capacity = AVAudioFrameCount(frameCount)
        guard let pcm = AVAudioPCMBuffer(pcmFormat: audioFmt, frameCapacity: capacity) else {
            return nil
        }
        pcm.frameLength = capacity

        guard let blockBuf = CMSampleBufferGetDataBuffer(sbuf) else { return nil }

        var srcPtr: UnsafeMutablePointer<Int8>?
        var srcLen = 0
        guard CMBlockBufferGetDataPointer(blockBuf, atOffset: 0,
                                          lengthAtOffsetOut: nil,
                                          totalLengthOut: &srcLen,
                                          dataPointerOut: &srcPtr) == noErr,
              let src = srcPtr else { return nil }

        let dst = pcm.mutableAudioBufferList.pointee.mBuffers
        let copyLen = min(srcLen, Int(dst.mDataByteSize))
        memcpy(dst.mData, src, copyLen)

        return pcm
    }
}

enum CaptureError: LocalizedError {
    case bufferConversionFailed

    var errorDescription: String? {
        switch self {
        case .bufferConversionFailed: return "Failed to convert captured audio buffer."
        }
    }
}
