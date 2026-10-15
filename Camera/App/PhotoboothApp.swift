import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct PhotoboothApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Photobooth", id: "main") {
            ContentView()
        }
        .defaultSize(width: 960, height: 640)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }
    }
}
