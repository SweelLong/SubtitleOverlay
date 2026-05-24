import AppKit
import Speech

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestSpeechPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup handled by individual services via deinit.
    }

    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("[SubtitleOverlay] Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    print("[SubtitleOverlay] Speech recognition not authorized: \(status.rawValue)")
                @unknown default:
                    break
                }
            }
        }
    }
}
