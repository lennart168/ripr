import Foundation
import AppKit
import Combine

public enum AppUpdateState: Equatable {
    case idle
    case checking
    case available(version: String, notes: String, downloadUrl: URL?)
    case downloading(progress: Double, bytesWritten: Int64, totalBytes: Int64)
    case extracting
    case readyToInstall(version: String)
    case installing
    case upToDate
    case error(message: String)

    public var isDownloadingOrExtracting: Bool {
        switch self {
        case .downloading, .extracting: return true
        default: return false
        }
    }
}

// MARK: - Download Progress Helper
private final class DownloadDelegateHelper: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let onProgress: @Sendable (Double, Int64, Int64) -> Void
    private let onCompletion: @Sendable (URL?, Error?) -> Void

    init(
        onProgress: @escaping @Sendable (Double, Int64, Int64) -> Void,
        onCompletion: @escaping @Sendable (URL?, Error?) -> Void
    ) {
        self.onProgress = onProgress
        self.onCompletion = onCompletion
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0
        onProgress(progress, totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Die temporäre Datei muss an einen stabilen Ort kopiert werden bevor die Methode zurückkehrt
        let tempDestination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ripr_download_\(UUID().uuidString).dmg")
        do {
            try? FileManager.default.removeItem(at: tempDestination)
            try FileManager.default.moveItem(at: location, to: tempDestination)
            onCompletion(tempDestination, nil)
        } catch {
            onCompletion(nil, error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onCompletion(nil, error)
        }
    }
}

// MARK: - App Updater Service
@MainActor
public final class AppUpdaterService: ObservableObject {
    public static let shared = AppUpdaterService()

    public nonisolated static let repository = "lennart168/ripr"

    @Published public private(set) var state: AppUpdateState = .idle
    @Published public private(set) var currentVersion: String = "1.0.0"
    @Published public private(set) var latestVersion: String? = nil
    @Published public private(set) var releaseNotes: String = ""
    @Published public private(set) var statusMessage: String = ""
    @Published public var showBanner: Bool = false

    private var currentDownloadTask: URLSessionDownloadTask?
    private var stagedAppPath: String?

    private init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Semantic Version Comparison
    public static func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let clean1 = v1.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\r\n"))
        let clean2 = v2.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\r\n"))

        let parts1 = clean1.split(separator: ".").compactMap { Int($0) }
        let parts2 = clean2.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 < p2 { return .orderedAscending }
            if p1 > p2 { return .orderedDescending }
        }
        return .orderedSame
    }

    // MARK: - Update Check (Manual & Automatic)
    public func checkForUpdates(silent: Bool = false) {
        if !silent {
            self.state = .checking
            self.statusMessage = "Prüfe auf Updates für ripr..."
        }

        Task {
            do {
                let release = try await self.fetchLatestRelease()
                let releaseTag = release.tag_name
                let cleanTag = releaseTag.trimmingCharacters(in: CharacterSet(charactersIn: "vV \t\r\n"))

                let isNewer = Self.compareVersions(self.currentVersion, cleanTag) == .orderedAscending

                if isNewer {
                    self.latestVersion = cleanTag
                    self.releaseNotes = release.body ?? ""
                    self.statusMessage = "Neue Version \(cleanTag) verfügbar!"
                    self.showBanner = true

                    let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") })
                        ?? release.assets.first(where: { $0.name.lowercased().hasSuffix(".zip") })

                    let downloadUrl = dmgAsset.flatMap { URL(string: $0.browser_download_url) }
                        ?? URL(string: "https://github.com/\(Self.repository)/releases/download/\(releaseTag)/ripr.dmg")

                    self.state = .available(version: cleanTag, notes: self.releaseNotes, downloadUrl: downloadUrl)

                    // Wenn automatischer Download aktiviert ist, direkt laden
                    if SettingsManager.shared.autoDownloadAppUpdates, let downloadUrl = downloadUrl {
                        self.startDownload(url: downloadUrl, version: cleanTag)
                    }
                } else {
                    self.latestVersion = cleanTag
                    if !silent {
                        self.state = .upToDate
                        self.statusMessage = "ripr ist aktuell (v\(self.currentVersion))."
                    } else if case .idle = self.state {
                        // Nichts ändern
                    }
                }
            } catch {
                if !silent {
                    self.state = .error(message: error.localizedDescription)
                    self.statusMessage = "Update-Prüfung fehlgeschlagen."
                }
            }
        }
    }

    public func checkSilentlyInBackground() async {
        guard SettingsManager.shared.autoCheckAppUpdates else { return }

        // Throttle: Maximal alle 4 Stunden automatisch prüfen
        let defaults = UserDefaults.standard
        let lastCheckKey = "lastRiprAppAutoCheckTimestamp"
        let now = Date().timeIntervalSince1970
        let lastCheck = defaults.double(forKey: lastCheckKey)
        if lastCheck > 0 && (now - lastCheck) < (4 * 3600) {
            return
        }
        defaults.set(now, forKey: lastCheckKey)

        checkForUpdates(silent: true)
    }

    // MARK: - Download Update
    public func startDownload(url: URL? = nil, version: String? = nil) {
        let targetVersion = version ?? self.latestVersion ?? "neueste"
        guard let downloadUrl = url ?? {
            if case let .available(_, _, u) = self.state { return u }
            return URL(string: "https://github.com/\(Self.repository)/releases/latest/download/ripr.dmg")
        }() else {
            self.state = .error(message: "Keine gültige Download-URL vorhanden.")
            return
        }

        self.state = .downloading(progress: 0.0, bytesWritten: 0, totalBytes: 0)
        self.statusMessage = "Lade ripr v\(targetVersion) herunter..."
        self.showBanner = true

        let delegate = DownloadDelegateHelper(
            onProgress: { [weak self] progress, written, total in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.state = .downloading(progress: progress, bytesWritten: written, totalBytes: total)
                    let mbWritten = String(format: "%.1f", Double(written) / (1024 * 1024))
                    let mbTotal = total > 0 ? String(format: "%.1f", Double(total) / (1024 * 1024)) + " MB" : "? MB"
                    let pct = Int(progress * 100)
                    self.statusMessage = "Lade Update: \(pct)% (\(mbWritten) / \(mbTotal))"
                }
            },
            onCompletion: { [weak self] tempUrl, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if let error = error {
                        self.state = .error(message: error.localizedDescription)
                        self.statusMessage = "Download fehlgeschlagen."
                        return
                    }
                    guard let tempUrl = tempUrl else {
                        self.state = .error(message: "Keine Download-Datei empfangen.")
                        return
                    }

                    self.extractAndStageUpdate(dmgUrl: tempUrl, version: targetVersion)
                }
            }
        )

        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        var request = URLRequest(url: downloadUrl)
        request.setValue("ripr-mac-updater", forHTTPHeaderField: "User-Agent")
        let task = session.downloadTask(with: request)
        self.currentDownloadTask = task
        task.resume()
    }

    public func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        state = .idle
        statusMessage = "Download abgebrochen."
    }

    // MARK: - Extract & Stage DMG
    private func extractAndStageUpdate(dmgUrl: URL, version: String) {
        self.state = .extracting
        self.statusMessage = "Bereite Installation von v\(version) vor..."

        Task.detached(priority: .userInitiated) {
            do {
                let staged = try self.extractAppFromDMG(dmgPath: dmgUrl.path)
                try? FileManager.default.removeItem(at: dmgUrl)

                await MainActor.run {
                    self.stagedAppPath = staged
                    self.state = .readyToInstall(version: version)
                    self.statusMessage = "ripr v\(version) ist bereit zur Installation!"
                    self.showBanner = true
                }
            } catch {
                try? FileManager.default.removeItem(at: dmgUrl)
                await MainActor.run {
                    self.state = .error(message: error.localizedDescription)
                    self.statusMessage = "Entpacken fehlgeschlagen: \(error.localizedDescription)"
                }
            }
        }
    }

    private nonisolated func extractAppFromDMG(dmgPath: String) throws -> String {
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", "-nobrowse", "-readonly", "-plist", dmgPath]

        let pipe = Pipe()
        mountProcess.standardOutput = pipe
        mountProcess.standardError = Pipe()

        try mountProcess.run()
        mountProcess.waitUntilExit()

        guard mountProcess.terminationStatus == 0 else {
            throw NSError(
                domain: "AppUpdater",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Konnte ripr.dmg nicht mounten (Exit-Code \(mountProcess.terminationStatus))."]
            )
        }

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let plist = try? PropertyListSerialization.propertyList(from: outputData, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]] else {
            throw NSError(
                domain: "AppUpdater",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Konnte Mount-Informationen des DMG nicht verarbeiten."]
            )
        }

        guard let mountPoint = entities.compactMap({ $0["mount-point"] as? String }).first else {
            throw NSError(
                domain: "AppUpdater",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Kein Mount-Point im Disk Image gefunden."]
            )
        }

        defer {
            let detachProcess = Process()
            detachProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detachProcess.arguments = ["detach", mountPoint, "-force"]
            try? detachProcess.run()
            detachProcess.waitUntilExit()
        }

        let fm = FileManager.default
        let contents = (try? fm.contentsOfDirectory(atPath: mountPoint)) ?? []
        guard let appName = contents.first(where: { $0.hasSuffix(".app") }) else {
            throw NSError(
                domain: "AppUpdater",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Keine .app im Disk-Image gefunden."]
            )
        }

        let mountedAppPath = (mountPoint as NSString).appendingPathComponent(appName)

        // Staging Verzeichnis erstellen
        let stagingDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ripr_staged_\(UUID().uuidString)")
        try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        let stagedAppPath = stagingDir.appendingPathComponent(appName).path

        if fm.fileExists(atPath: stagedAppPath) {
            try? fm.removeItem(atPath: stagedAppPath)
        }
        try fm.copyItem(atPath: mountedAppPath, toPath: stagedAppPath)

        // Quarantäne entfernen, damit Gatekeeper das Update nach Neustart nicht blockiert
        let xattr = Process()
        xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        xattr.arguments = ["-cr", stagedAppPath]
        try? xattr.run()
        xattr.waitUntilExit()

        return stagedAppPath
    }

    // MARK: - Install & Relaunch
    public func installAndRelaunch() {
        guard let staged = self.stagedAppPath, FileManager.default.fileExists(atPath: staged) else {
            self.state = .error(message: "Installationsdateien nicht gefunden.")
            return
        }

        self.state = .installing
        self.statusMessage = "Installiere Update und starte ripr neu..."

        let targetAppPath = getTargetAppPath()
        let currentPid = ProcessInfo.processInfo.processIdentifier

        let scriptPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ripr_updater_\(UUID().uuidString).sh").path

        let scriptContent = """
        #!/bin/bash
        PID="\(currentPid)"
        STAGED="\(staged)"
        TARGET="\(targetAppPath)"

        # 1. Warten bis der alte Prozess beendet ist
        while kill -0 "$PID" 2>/dev/null; do
            sleep 0.15
        done

        sleep 0.2

        # 2. Bestehende App ersetzen
        if rm -rf "$TARGET" 2>/dev/null && cp -R "$STAGED" "$TARGET" 2>/dev/null; then
            xattr -cr "$TARGET" 2>/dev/null || true
            chmod -R u+rx "$TARGET" 2>/dev/null || true
            rm -rf "$STAGED" "$(dirname "$STAGED")" 2>/dev/null || true
            open "$TARGET"
            exit 0
        fi

        # 3. Fallback: Falls keine Schreibrechte auf Zielordner, Admin-Rechte via AppleScript
        osascript -e "do shell script \\"rm -rf '$TARGET' && cp -R '$STAGED' '$TARGET' && xattr -cr '$TARGET'\\" with administrator privileges" 2>/dev/null || true
        rm -rf "$STAGED" "$(dirname "$STAGED")" 2>/dev/null || true
        open "$TARGET"
        """

        do {
            try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [scriptPath]
            try process.run()

            // App beenden damit der Installer das Bundle austauschen und neu starten kann
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            self.state = .error(message: "Konnte Installationsskript nicht ausführen: \(error.localizedDescription)")
        }
    }

    private func getTargetAppPath() -> String {
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.hasSuffix(".app") {
            return bundlePath
        }

        // Falls ripr während der Entwicklung als Binärdatei gestartet wurde:
        let standardApp = "/Applications/ripr.app"
        if FileManager.default.fileExists(atPath: standardApp) {
            return standardApp
        }
        let userApp = NSString(string: "~/Applications/ripr.app").expandingTildeInPath
        if FileManager.default.fileExists(atPath: userApp) {
            return userApp
        }
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("ripr.app").path
    }

    // MARK: - GitHub API
    private struct GitHubAssetResponse: Codable {
        let name: String
        let browser_download_url: String
        let size: Int64?
    }

    private struct GitHubReleaseResponse: Codable {
        let tag_name: String
        let name: String?
        let body: String?
        let html_url: String?
        let draft: Bool?
        let prerelease: Bool?
        let assets: [GitHubAssetResponse]
    }

    private nonisolated func fetchLatestRelease() async throws -> GitHubReleaseResponse {
        let url = URL(string: "https://api.github.com/repos/\(Self.repository)/releases/latest")!
        var req = URLRequest(url: url)
        req.setValue("ripr-mac", forHTTPHeaderField: "User-Agent")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 8.0

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "AppUpdater", code: -1, userInfo: [NSLocalizedDescriptionKey: "Ungültige Serverantwort."])
        }

        guard http.statusCode == 200 else {
            throw NSError(domain: "AppUpdater", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "GitHub API Fehler (HTTP \(http.statusCode))."])
        }

        let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
        return release
    }
}
