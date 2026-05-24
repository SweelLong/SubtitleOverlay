import SwiftUI

@main
struct SubtitleOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Subtitle Overlay", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 320)

        Settings {
            SettingsView()
        }
    }
}
