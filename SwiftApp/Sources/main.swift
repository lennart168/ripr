import SwiftUI
import AppKit

@main
struct RiprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 900, height: 680)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            SidebarCommands()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.title = "ripr"
                window.isOpaque = false
                window.backgroundColor = .clear
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
                window.isMovableByWindowBackground = true

                // Feste, passende Fenstergröße festlegen & Resizing sperren
                let fixedSize = NSSize(width: 900, height: 680)
                window.setContentSize(fixedSize)
                window.minSize = fixedSize
                window.maxSize = fixedSize
                window.styleMask.remove(.resizable)
                window.center()
            }
        }

        // Geräuschloser Hintergrund-Update-Check für yt-dlp
        Task.detached(priority: .background) {
            await UpdaterService.shared.checkAndUpdateSilentlyInBackground()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
