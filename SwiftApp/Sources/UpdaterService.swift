import Foundation
import Combine

@MainActor
public final class UpdaterService: ObservableObject {
    public static let shared = UpdaterService()

    @Published public var currentVersion: String = "Lade..."
    @Published public var latestVersion: String? = nil
    @Published public var isChecking: Bool = false
    @Published public var isUpdating: Bool = false
    @Published public var statusMessage: String = ""
    @Published public var ffmpegStatus: String = "Lade..."

    private init() {
        refreshStatus()
    }

    public func refreshStatus() {
        // 1. FFmpeg Status
        let (ok, msg) = ProcessHelper.checkFFmpeg()
        if ok {
            self.ffmpegStatus = "FFmpeg aktiv: \(msg)"
        } else {
            self.ffmpegStatus = "\(msg)"
        }

        // 2. yt-dlp Version
        Task.detached(priority: .userInitiated) {
            let ver = self.fetchInstalledYtdlpVersion()
            await MainActor.run {
                self.currentVersion = ver
            }
        }
    }

    public func checkForUpdates() {
        isChecking = true
        statusMessage = "Suche nach neuester Version auf GitHub..."

        Task.detached(priority: .userInitiated) {
            let current = self.fetchInstalledYtdlpVersion()
            let latest = await self.fetchLatestGithubRelease()

            await MainActor.run {
                self.isChecking = false
                self.currentVersion = current
                self.latestVersion = latest

                if let latest = latest {
                    if latest != current {
                        self.statusMessage = "Neue Version verfügbar: \(latest) (Aktuell: \(current))"
                    } else {
                        self.statusMessage = "Du hast bereits die neueste Version (\(current))."
                    }
                } else {
                    self.statusMessage = "Konnte GitHub Releases nicht abfragen."
                }
            }
        }
    }

    public func checkAndUpdateSilentlyInBackground() async {
        guard SettingsManager.shared.autoUpdateYtDlp else { return }

        // Throttle: Maximal einmal alle 12 Stunden automatisch prüfen
        let defaults = UserDefaults.standard
        let lastCheckKey = "lastYtdlpAutoCheckTimestamp"
        let now = Date().timeIntervalSince1970
        let lastCheck = defaults.double(forKey: lastCheckKey)
        if lastCheck > 0 && (now - lastCheck) < (12 * 3600) {
            return
        }
        defaults.set(now, forKey: lastCheckKey)

        // 1. Neueste Version von GitHub abfragen
        guard let latest = await fetchLatestGithubRelease() else { return }
        let current = fetchInstalledYtdlpVersion()

        // 2. Prüfen ob ein Update vorliegt (z. B. "2026.08.19" < "2026.09.01")
        if latest > current && current != "Unbekannt" {
            let targetDir = ProcessHelper.appSupportBinDir
            try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            let targetFile = targetDir.appendingPathComponent("yt-dlp")

            let downloadURL = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos")!

            do {
                let (tempURL, response) = try await URLSession.shared.download(from: downloadURL)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }

                if FileManager.default.fileExists(atPath: targetFile.path) {
                    try? FileManager.default.removeItem(at: targetFile)
                }
                try FileManager.default.moveItem(at: tempURL, to: targetFile)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetFile.path)

                let newVer = self.fetchInstalledYtdlpVersion()
                await MainActor.run {
                    self.currentVersion = newVer
                    self.latestVersion = newVer
                    self.statusMessage = "yt-dlp automatisch im Hintergrund auf Version \(newVer) aktualisiert!"
                }
            } catch {}
        }
    }

    public func performUpdate() {
        isUpdating = true
        statusMessage = "Lade neueste yt-dlp Version von GitHub herunter..."

        Task.detached(priority: .userInitiated) {
            let targetDir = ProcessHelper.appSupportBinDir
            try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
            let targetFile = targetDir.appendingPathComponent("yt-dlp")

            let downloadURL = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos")!

            do {
                let (tempURL, response) = try await URLSession.shared.download(from: downloadURL)
                guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    throw NSError(domain: "UpdaterService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download fehlgeschlagen"])
                }

                if FileManager.default.fileExists(atPath: targetFile.path) {
                    try? FileManager.default.removeItem(at: targetFile)
                }
                try FileManager.default.moveItem(at: tempURL, to: targetFile)
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetFile.path)

                let newVer = self.fetchInstalledYtdlpVersion()
                await MainActor.run {
                    self.isUpdating = false
                    self.currentVersion = newVer
                    self.statusMessage = "Erfolgreich auf Version \(newVer) aktualisiert!"
                }
            } catch {
                // Fallback via pip falls vorhanden
                let pythonPath = ProcessHelper.findPython()
                let process = Process()
                process.executableURL = URL(fileURLWithPath: pythonPath)
                process.arguments = ["-m", "pip", "install", "--upgrade", "yt-dlp"]
                process.environment = ProcessHelper.makeEnvironment()
                try? process.run()
                process.waitUntilExit()

                let newVer = self.fetchInstalledYtdlpVersion()
                await MainActor.run {
                    self.isUpdating = false
                    self.currentVersion = newVer
                    self.statusMessage = "Update abgeschlossen (Version \(newVer))."
                }
            }
        }
    }

    private nonisolated func fetchInstalledYtdlpVersion() -> String {
        let (ytdlpPath, isPythonModule) = ProcessHelper.findYtDlp()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        process.arguments = isPythonModule ? ["-m", "yt_dlp", "--version"] : ["--version"]
        process.environment = ProcessHelper.makeEnvironment()

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
                return str
            }
        } catch {}
        return "Unbekannt"
    }

    private nonisolated func fetchLatestGithubRelease() async -> String? {
        guard let url = URL(string: "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest") else { return nil }
        var req = URLRequest(url: url)
        req.setValue("ripr-mac", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 6.0

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tag = json["tag_name"] as? String {
                    return tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                }
            }
        } catch {}
        return nil
    }
}
