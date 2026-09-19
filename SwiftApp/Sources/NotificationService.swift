import Foundation
import AppKit
import UserNotifications

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    public static let shared = NotificationService()

    public static let categoryIdentifier = "DOWNLOAD_FINISHED"
    public static let actionShowInFinder = "SHOW_IN_FINDER"
    public static let actionOpenFile = "OPEN_FILE"

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

        // 2. Kategorie mit Aktionen verknüpfen
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [showInFinderAction, openFileAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])

        // 3. Berechtigungen anfordern
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification Authorization Error: \(error)")
            }
        }
    }

    public func notifyDownloadFinished(title: String, filePath: String) {
        guard SettingsManager.shared.sendDownloadNotification else { return }
        guard !filePath.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚡ Download abgeschlossen"
        let displayTitle = title.isEmpty ? URL(fileURLWithPath: filePath).lastPathComponent : title
        content.subtitle = displayTitle
        content.body = "Klicke hier oder auf „Im Finder anzeigen“, um die Datei zu öffnen."
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["filePath": filePath]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Sofort ausliefern
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fehler beim Hinzufügen der Benachrichtigung: \(error)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Benachrichtigung auch dann anzeigen, wenn die App im Vordergrund aktiv ist
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    // Reaktion auf Klick auf Banner oder Action-Button
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
                    // Klick auf Button "Im Finder anzeigen" oder Klick direkt auf das Banner
                    if FileManager.default.fileExists(atPath: filePath) {
                        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    } else {
                        // Falls die Datei nicht existiert, Ordner öffnen
                        NSWorkspace.shared.open(fileURL.deletingLastPathComponent())
                    }
                default:
                    if FileManager.default.fileExists(atPath: filePath) {
                        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    }
                }
            }
        }

        completionHandler()
    }
}
