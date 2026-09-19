import Foundation
import AppKit
import SwiftUI
import UserNotifications
import Combine

public struct FinishedDownloadInfo: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let filePath: String
}

public final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationService()

    public static let categoryIdentifier = "DOWNLOAD_FINISHED"
    public static let actionShowInFinder = "SHOW_IN_FINDER"
    public static let actionOpenFile = "OPEN_FILE"

    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var latestFinishedDownload: FinishedDownloadInfo? = nil
    @Published public var showInAppToast: Bool = false

    private override init() {
        super.init()
    }

    public func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // 1. Aktionen definieren
        let showInFinderAction = UNNotificationAction(
            identifier: Self.actionShowInFinder,
            title: "Im Finder anzeigen",
            options: [.foreground]
        )

        let openFileAction = UNNotificationAction(
            identifier: Self.actionOpenFile,
            title: "Öffnen",
            options: [.foreground]
        )

        // 2. Kategorie registrieren
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [showInFinderAction, openFileAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])

        // 3. Status abfragen & initial anfragen
        refreshStatus()
        requestAuthorization()
    }

    public func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    public func requestAuthorization(completion: (@Sendable (Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            self?.refreshStatus()
            completion?(granted)
        }
    }

    public func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openFile(atPath path: String) {
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(fileURL)
        }
    }

    public func showInFinder(atPath path: String) {
        let fileURL = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if isDir.boolValue {
                NSWorkspace.shared.open(fileURL)
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            }
        } else {
            NSWorkspace.shared.open(fileURL.deletingLastPathComponent())
        }
    }

    public func notifyDownloadFinished(title: String, filePath: String) {
        guard SettingsManager.shared.sendDownloadNotification else { return }
        guard !filePath.isEmpty else { return }

        let displayTitle = title.isEmpty ? URL(fileURLWithPath: filePath).lastPathComponent : title
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent

        // 1. In-App Toast & Audio/Dock Feedback
        DispatchQueue.main.async {
            self.latestFinishedDownload = FinishedDownloadInfo(title: displayTitle, filePath: filePath)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                self.showInAppToast = true
            }

            // Subtiler Systemton & Dock Bounce
            NSSound(named: "Glass")?.play()
            NSApp.requestUserAttention(.informationalRequest)

            // Automatisches Ausblenden des In-App Toasts nach 7 Sekunden
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                withAnimation {
                    self.showInAppToast = false
                }
            }
        }

        // 2. System Notification via UNUserNotificationCenter
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }

            if settings.authorizationStatus == .authorized {
                self.sendUNNotification(title: displayTitle, fileName: fileName, filePath: filePath)
            } else {
                // Falls noch nicht erlaubt:
                if settings.authorizationStatus == .notDetermined {
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        self.refreshStatus()
                        if granted {
                            self.sendUNNotification(title: displayTitle, fileName: fileName, filePath: filePath)
                            return
                        }
                    }
                }

                // Sofortiges natives macOS-Banner via AppleScript (funktioniert immer)
                self.sendAppleScriptNotification(title: displayTitle, fileName: fileName)
            }
        }
    }

    public func sendTestNotification() {
        let samplePath = SettingsManager.shared.downloadFolder.path
        notifyDownloadFinished(title: "Test-Download (ripr)", filePath: samplePath)
    }

    private func sendUNNotification(title: String, fileName: String, filePath: String) {
        let content = UNMutableNotificationContent()
        content.title = "⚡ Download abgeschlossen"
        content.subtitle = title
        content.body = "„\(fileName)“ wurde erfolgreich gesichert."
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["filePath": filePath]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if error != nil {
                self?.sendAppleScriptNotification(title: title, fileName: fileName)
            }
        }
    }

    private func sendAppleScriptNotification(title: String, fileName: String) {
        let safeTitle = title.replacingOccurrences(of: "\"", with: "'")
        let safeName = fileName.replacingOccurrences(of: "\"", with: "'")
        let script = "display notification \"\(safeName) wurde gespeichert.\" with title \"⚡ ripr: Download fertig\" subtitle \"\(safeTitle)\" sound name \"Glass\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let filePath = userInfo["filePath"] as? String {
            let fileURL = URL(fileURLWithPath: filePath)

            DispatchQueue.main.async {
                switch response.actionIdentifier {
                case Self.actionOpenFile:
                    if FileManager.default.fileExists(atPath: filePath) {
                        NSWorkspace.shared.open(fileURL)
                    }
                case Self.actionShowInFinder, UNNotificationDefaultActionIdentifier:
                    self.showInFinder(atPath: filePath)
                default:
                    self.showInFinder(atPath: filePath)
                }
            }
        }

        completionHandler()
    }
}
