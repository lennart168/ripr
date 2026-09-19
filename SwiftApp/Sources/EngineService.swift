import Foundation
import AppKit
import Combine

@MainActor
public final class EngineService: ObservableObject {
    @Published public var isDownloading: Bool = false
    @Published public var isAnalyzing: Bool = false
    @Published public var isLive: Bool = false
    @Published public var isPlaylist: Bool = false
    @Published public var playlistCurrentItem: Int = 0
    @Published public var playlistTotalItems: Int = 0
    @Published public var percent: Double = 0.0
    @Published public var statusText: String = "Bereit"
    @Published public var etaText: String = ""
    @Published public var detailsText: String = ""
    @Published public var finishedFilePath: String? = nil
    @Published public var errorMessage: String? = nil
    @Published public var isConverting: Bool = false

    private var currentProcess: Process?
    private var isCancelled: Bool = false
    private var isStoppingLive: Bool = false
    private var startTime: Date = Date()
    private var liveTimer: Timer?

    public init() {}

    public func startAnalyzing() {
        self.isAnalyzing = true
        self.isDownloading = false
        self.statusText = "Video-Informationen & Qualitätsstufen werden geladen..."
        self.etaText = "Bitte einen kurzen Moment warten..."
        self.detailsText = "Verbindung zur Plattform wird aufgebaut..."
        self.errorMessage = nil
        self.finishedFilePath = nil
    }

    public func finishAnalyzing() {
        self.isAnalyzing = false
        self.statusText = "Bereit"
        self.etaText = ""
        self.detailsText = ""
    }

    public func reset() {
        self.isDownloading = false
        self.isAnalyzing = false
        self.isLive = false
        self.isPlaylist = false
        self.playlistCurrentItem = 0
        self.playlistTotalItems = 0
        self.percent = 0.0
        self.statusText = "Bereit"
        self.etaText = ""
        self.detailsText = ""
        self.finishedFilePath = nil
        self.errorMessage = nil
    }

    public func cancel() {
        isCancelled = true
        if isLive {
            isStoppingLive = true
            statusText = "Live-Aufnahme wird finalisiert & gespeichert..."
            currentProcess?.interrupt()
        } else if isConverting {
            statusText = "Konvertierung wird abgebrochen..."
            currentProcess?.terminate()
            isConverting = false
        } else {
            statusText = "Download wird abgebrochen..."
            currentProcess?.interrupt()
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.currentProcess?.terminate()
            }
        }
    }

    public func startDownload(
        url: String,
        format: FormatOption,
        outputFolder: URL,
        platform: Platform,
        isLive: Bool,
        convertToH265: Bool = false,
        title: String = "",
        uploader: String = "",
        thumbnailURL: String? = nil
    ) {
        self.isDownloading = true
        self.isAnalyzing = false
        self.isLive = isLive
        self.isCancelled = false
        self.isStoppingLive = false
        self.isConverting = false
        self.percent = 0.0
        self.errorMessage = nil
        self.finishedFilePath = nil
        self.startTime = Date()

        if isLive {
            self.statusText = "Live-Aufnahme läuft..."
            self.etaText = "Aufnahmedauer: 00:00"
            self.detailsText = "Live-Stream wird gesichert..."
            startLiveTimer()
        } else {
            self.statusText = "Download wird vorbereitet (0%)..."
            self.etaText = "Verbleibende Zeit: Berechne..."
            self.detailsText = "Verbindung wird hergestellt..."
        }

        Task {
            await self.executeDownload(
                url: url,
                format: format,
                outputFolder: outputFolder,
                platform: platform,
                isLive: isLive,
                useCookies: true,
                convertToH265: convertToH265,
                title: title,
                uploader: uploader,
                thumbnailURL: thumbnailURL
            )
        }
    }

    private func startLiveTimer() {
        liveTimer?.invalidate()
        liveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isLive, self.isDownloading else { return }
                let elapsed = Int(Date().timeIntervalSince(self.startTime))
                let m = elapsed / 60
                let s = elapsed % 60
                let h = m / 60
                let remM = m % 60
                let timeStr = h > 0 ? String(format: "%d:%02d:%02d", h, remM, s) : String(format: "%02d:%02d", remM, s)
                self.etaText = "Laufende Aufnahmedauer: \(timeStr)"
            }
        }
    }

    private func stopLiveTimer() {
        liveTimer?.invalidate()
        liveTimer = nil
    }

    private func executeDownload(
        url: String,
        format: FormatOption,
        outputFolder: URL,
        platform: Platform,
        isLive: Bool,
        useCookies: Bool,
        convertToH265: Bool = false,
        title: String = "",
        uploader: String = "",
        thumbnailURL: String? = nil
    ) async {
        let (ytdlpPath, isPythonModule) = ProcessHelper.findYtDlp()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)

        let outtmpl = outputFolder.appendingPathComponent("%(title)s [%(id)s].%(ext)s").path

        var args: [String] = []
        if isPythonModule {
            args.append(contentsOf: ["-m", "yt_dlp"])
        }
        args.append(contentsOf: [
            "--newline",
            "--no-part",
            "--remote-components", "ejs:github",
            "--progress-template", "download:DOWNLOAD_PROGRESS:%(progress._percent_str)s|%(progress._total_bytes_str,progress._total_bytes_estimate_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._downloaded_bytes_str)s",
            "-o", outtmpl
        ])

        if useCookies {
            let cookieArgs = SettingsManager.shared.getCookieArgs(for: platform)
            args.append(contentsOf: cookieArgs)
        }

        if format.isAudioOnly {
            args.append(contentsOf: [
                "-x",
                "--audio-format", format.formatExt,
                "--audio-quality", "0"
            ])
            if SettingsManager.shared.embedThumbnail { args.append("--embed-thumbnail") }
            if SettingsManager.shared.embedMetadata { args.append("--embed-metadata") }
        } else {
            if isLive {
                args.append(contentsOf: ["-f", format.selector.isEmpty ? "best" : format.selector, "--hls-use-mpegts"])
            } else {
                args.append(contentsOf: ["-f", format.selector, "--merge-output-format", "mp4"])
                if SettingsManager.shared.embedThumbnail { args.append("--embed-thumbnail") }
                if SettingsManager.shared.embedMetadata { args.append("--embed-metadata") }
            }
        }

        args.append(url)
        process.arguments = args
        process.environment = ProcessHelper.makeEnvironment()

        let pipeOut = Pipe()
        process.standardOutput = pipeOut
        process.standardError = pipeOut

        self.currentProcess = process

        do {
            try process.run()
        } catch {
            self.isDownloading = false
            self.stopLiveTimer()
            self.errorMessage = "Fehler beim Starten des Downloaders: \(error.localizedDescription)"
            return
        }

        var candidateFile = ""
        var capturedError = ""
        let fileHandle = pipeOut.fileHandleForReading

        do {
            for try await line in fileHandle.bytes.lines {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanLine.isEmpty { continue }

                if cleanLine.contains("[download] Destination:") {
                    let parts = cleanLine.components(separatedBy: "Destination:")
                    if parts.count > 1 {
                        candidateFile = parts[1].trimmingCharacters(in: .whitespaces)
                        self.finishedFilePath = candidateFile
                        self.statusText = "Download gestartet..."
                    }
                } else if cleanLine.contains("[Merger] Merging formats into") {
                    let parts = cleanLine.components(separatedBy: "into")
                    if parts.count > 1 {
                        candidateFile = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                        self.finishedFilePath = candidateFile
                        self.statusText = "Audio & Video werden mit FFmpeg zusammengeführt..."
                        self.etaText = "Fast fertig..."
                    }
                } else if cleanLine.contains("[ExtractAudio] Destination:") {
                    let parts = cleanLine.components(separatedBy: "Destination:")
                    if parts.count > 1 {
                        candidateFile = parts[1].trimmingCharacters(in: .whitespaces)
                        self.finishedFilePath = candidateFile
                        self.statusText = "Konvertiere Audio mit FFmpeg..."
                        self.etaText = "Fast fertig..."
                    }
                }

                // DOWNLOAD_PROGRESS Template
                if cleanLine.contains("DOWNLOAD_PROGRESS:") {
                    let payload = cleanLine.components(separatedBy: "DOWNLOAD_PROGRESS:").last ?? ""
                    let parts = payload.components(separatedBy: "|")
                    if parts.count >= 5 {
                        let pctRaw = parts[0].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
                        let pct = Double(pctRaw) ?? 0.0
                        let tot = parts[1].trimmingCharacters(in: .whitespaces)
                        let spd = parts[2].trimmingCharacters(in: .whitespaces)
                        let eta = parts[3].trimmingCharacters(in: .whitespaces)
                        let dl = parts[4].trimmingCharacters(in: .whitespaces)

                        if !self.isLive {
                            self.percent = pct
                            self.statusText = String(format: "Download läuft (%.1f%%)", pct)
                            self.etaText = "Verbleibende Zeit: \(formatFriendlyETA(eta))"

                            var infoParts: [String] = []
                            if !dl.isEmpty && dl != "NA" && !tot.isEmpty && tot != "NA" {
                                infoParts.append("\(dl) von \(tot)")
                            } else if !dl.isEmpty && dl != "NA" {
                                infoParts.append(dl)
                            }
                            if !spd.isEmpty && spd != "NA" && spd != "Unknown B/s" {
                                infoParts.append(spd)
                            }
                            self.detailsText = infoParts.joined(separator: "   •   ")
                        } else {
                            var infoParts: [String] = []
                            if !dl.isEmpty && dl != "NA" { infoParts.append("Gespeichert: \(dl)") }
                            if !spd.isEmpty && spd != "NA" && spd != "Unknown B/s" { infoParts.append("Datenrate: \(spd)") }
                            self.detailsText = infoParts.joined(separator: "   •   ")
                        }
                    }
                }

                if cleanLine.contains("ERROR:") || cleanLine.contains("Operation not permitted") {
                    capturedError = cleanLine
                }
            }
        } catch {
            print("Stream-Lese-Fehler: \(error)")
        }

        process.waitUntilExit()
        let exitCode = process.terminationStatus

        self.isDownloading = false
        self.stopLiveTimer()

        if self.isLive && (self.isStoppingLive || self.isCancelled) {
            self.percent = 100.0
            self.statusText = "Live-Aufnahme erfolgreich gesichert"
            self.etaText = "Aufnahme abgeschlossen"
            let finalPath = self.finishedFilePath ?? outputFolder.path
            self.detailsText = "Gespeichert in: \(finalPath)"

            if !finalPath.isEmpty {
                let itemTitle = title.isEmpty ? URL(fileURLWithPath: finalPath).lastPathComponent : title
                HistoryManager.shared.add(item: DownloadHistoryItem(
                    title: itemTitle,
                    uploader: uploader,
                    thumbnailURL: thumbnailURL,
                    filePath: finalPath,
                    formatDisplay: format.display,
                    platform: platform.rawValue
                ))
                NotificationService.shared.notifyDownloadFinished(title: itemTitle, filePath: finalPath)
            }
            return
        }

        if self.isCancelled {
            self.statusText = "Download abgebrochen"
            self.errorMessage = "Download wurde vom Benutzer abgebrochen."
            return
        }

        if exitCode == 0 {
            var finalPath = self.finishedFilePath ?? candidateFile
            var displayFormat = format.display

            if convertToH265 && !format.isAudioOnly && FileManager.default.fileExists(atPath: finalPath) {
                self.isConverting = true
                self.statusText = "Wird in H.265 (HEVC) umgewandelt..."
                self.detailsText = "Apple Silicon Hardware-Encoding via VideoToolbox..."
                self.etaText = "Konvertiere..."

                if let converted = await self.convertFileToH265(inputPath: finalPath) {
                    finalPath = converted
                    self.finishedFilePath = converted
                    displayFormat = "\(format.display) • H.265"
                }
                self.isConverting = false
            }

            self.percent = 100.0
            self.statusText = (convertToH265 && !format.isAudioOnly) ? "Download & H.265-Konvertierung abgeschlossen (100%)" : "Download erfolgreich abgeschlossen (100%)"
            self.etaText = "Fertiggestellt"
            let name = URL(fileURLWithPath: finalPath).lastPathComponent
            self.detailsText = "Gespeichert als: \(name)"

            if !finalPath.isEmpty {
                let itemTitle = title.isEmpty ? name : title
                HistoryManager.shared.add(item: DownloadHistoryItem(
                    title: itemTitle,
                    uploader: uploader,
                    thumbnailURL: thumbnailURL,
                    filePath: finalPath,
                    formatDisplay: displayFormat,
                    platform: platform.rawValue
                ))
                NotificationService.shared.notifyDownloadFinished(title: itemTitle, filePath: finalPath)
            }
        } else {
            if useCookies && (capturedError.contains("Operation not permitted") || capturedError.lowercased().contains("cookies")) {
                print("Download mit Cookies fehlgeschlagen, wiederhole ohne Cookies...")
                Task {
                    await self.executeDownload(
                        url: url,
                        format: format,
                        outputFolder: outputFolder,
                        platform: platform,
                        isLive: isLive,
                        useCookies: false,
                        convertToH265: convertToH265,
                        title: title,
                        uploader: uploader,
                        thumbnailURL: thumbnailURL
                    )
                }
                return
            }
            self.statusText = "Download fehlgeschlagen"
            self.errorMessage = capturedError.isEmpty ? "Download-Prozess beendet mit Fehlercode \(exitCode)" : capturedError
        }
    }

    public func startPlaylistDownload(
        playlist: PlaylistMetadata,
        selectedIndices: [Int],
        format: FormatOption,
        outputFolder: URL,
        platform: Platform,
        createSubfolder: Bool = true,
        numberFiles: Bool = true
    ) {
        self.isDownloading = true
        self.isAnalyzing = false
        self.isLive = false
        self.isPlaylist = true
        self.isCancelled = false
        self.isConverting = false
        self.percent = 0.0
        self.errorMessage = nil
        self.finishedFilePath = nil
        self.playlistCurrentItem = 1
        self.playlistTotalItems = selectedIndices.count
        self.startTime = Date()

        let total = selectedIndices.count
        self.statusText = "Playlist wird vorbereitet (0 von \(total))..."
        self.etaText = "Berechne..."
        self.detailsText = "Initialisiere Download von \(total) Elementen..."

        Task {
            await self.executePlaylistDownload(
                playlist: playlist,
                selectedIndices: selectedIndices,
                format: format,
                outputFolder: outputFolder,
                platform: platform,
                createSubfolder: createSubfolder,
                numberFiles: numberFiles,
                useCookies: true
            )
        }
    }

    private func executePlaylistDownload(
        playlist: PlaylistMetadata,
        selectedIndices: [Int],
        format: FormatOption,
        outputFolder: URL,
        platform: Platform,
        createSubfolder: Bool,
        numberFiles: Bool,
        useCookies: Bool
    ) async {
        let (ytdlpPath, isPythonModule) = ProcessHelper.findYtDlp()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)

        let targetFolder: URL
        if createSubfolder {
            let safeTitle = sanitizeFileName(playlist.title)
            targetFolder = outputFolder.appendingPathComponent(safeTitle, isDirectory: true)
            try? FileManager.default.createDirectory(at: targetFolder, withIntermediateDirectories: true)
        } else {
            targetFolder = outputFolder
        }

        let outtmpl: String
        if numberFiles {
            outtmpl = targetFolder.appendingPathComponent("%(playlist_index)02d - %(title)s [%(id)s].%(ext)s").path
        } else {
            outtmpl = targetFolder.appendingPathComponent("%(title)s [%(id)s].%(ext)s").path
        }

        var args: [String] = []
        if isPythonModule {
            args.append(contentsOf: ["-m", "yt_dlp"])
        }
        args.append(contentsOf: [
            "--newline",
            "--no-part",
            "--ignore-errors",
            "--no-abort-on-error",
            "--remote-components", "ejs:github",
            "--progress-template", "download:DOWNLOAD_PROGRESS:%(progress._percent_str)s|%(progress._total_bytes_str,progress._total_bytes_estimate_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._downloaded_bytes_str)s",
            "-o", outtmpl
        ])

        if !selectedIndices.isEmpty && selectedIndices.count < playlist.items.count {
            let itemsArg = selectedIndices.map { String($0) }.joined(separator: ",")
            args.append(contentsOf: ["--playlist-items", itemsArg])
        }

        if useCookies {
            let cookieArgs = SettingsManager.shared.getCookieArgs(for: platform)
            args.append(contentsOf: cookieArgs)
        }

        if format.isAudioOnly {
            args.append(contentsOf: [
                "-x",
                "--audio-format", format.formatExt,
                "--audio-quality", "0"
            ])
            if SettingsManager.shared.embedThumbnail { args.append("--embed-thumbnail") }
            if SettingsManager.shared.embedMetadata { args.append("--embed-metadata") }
        } else {
            args.append(contentsOf: ["-f", format.selector, "--merge-output-format", "mp4"])
            if SettingsManager.shared.embedThumbnail { args.append("--embed-thumbnail") }
            if SettingsManager.shared.embedMetadata { args.append("--embed-metadata") }
        }

        args.append(playlist.webpageURL)
        process.arguments = args
        process.environment = ProcessHelper.makeEnvironment()

        let pipeOut = Pipe()
        process.standardOutput = pipeOut
        process.standardError = pipeOut

        self.currentProcess = process

        do {
            try process.run()
        } catch {
            self.isDownloading = false
            self.errorMessage = "Fehler beim Starten des Playlist-Downloaders: \(error.localizedDescription)"
            return
        }

        var currentItemIdx: Int = 1
        let totalItemsCount = max(1, selectedIndices.count)
        var currentItemTitle: String = ""
        var capturedError = ""
        let fileHandle = pipeOut.fileHandleForReading

        do {
            for try await line in fileHandle.bytes.lines {
                let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanLine.isEmpty { continue }

                if cleanLine.contains("Downloading item") && cleanLine.contains("of") {
                    let parts = cleanLine.components(separatedBy: "Downloading item")
                    if parts.count > 1 {
                        let sub = parts[1].trimmingCharacters(in: .whitespaces)
                        let numParts = sub.components(separatedBy: "of")
                        if numParts.count == 2,
                           let cur = Int(numParts[0].trimmingCharacters(in: .whitespaces)) {
                            currentItemIdx = cur
                            self.playlistCurrentItem = cur
                        }
                    }
                }

                if cleanLine.contains("[download] Destination:") {
                    let parts = cleanLine.components(separatedBy: "Destination:")
                    if parts.count > 1 {
                        let dest = parts[1].trimmingCharacters(in: .whitespaces)
                        currentItemTitle = URL(fileURLWithPath: dest).deletingPathExtension().lastPathComponent
                    }
                }

                if cleanLine.contains("DOWNLOAD_PROGRESS:") {
                    let payload = cleanLine.components(separatedBy: "DOWNLOAD_PROGRESS:").last ?? ""
                    let parts = payload.components(separatedBy: "|")
                    if parts.count >= 5 {
                        let pctRaw = parts[0].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
                        let itemPct = Double(pctRaw) ?? 0.0
                        let tot = parts[1].trimmingCharacters(in: .whitespaces)
                        let spd = parts[2].trimmingCharacters(in: .whitespaces)
                        let eta = parts[3].trimmingCharacters(in: .whitespaces)
                        let dl = parts[4].trimmingCharacters(in: .whitespaces)

                        let overallPct = (Double(max(0, currentItemIdx - 1)) + (itemPct / 100.0)) / Double(totalItemsCount) * 100.0
                        self.percent = min(100.0, max(0.0, overallPct))
                        self.statusText = "Lade Element \(currentItemIdx) von \(totalItemsCount) (\(String(format: "%.1f", overallPct))%)"
                        self.etaText = "Restzeit: \(formatFriendlyETA(eta))"

                        var details: [String] = []
                        if !currentItemTitle.isEmpty { details.append(currentItemTitle) }
                        if !dl.isEmpty && dl != "NA" && !tot.isEmpty && tot != "NA" { details.append("\(dl) von \(tot)") }
                        if !spd.isEmpty && spd != "NA" && spd != "Unknown B/s" { details.append(spd) }
                        self.detailsText = details.joined(separator: "   •   ")
                    }
                }

                if cleanLine.contains("ERROR:") || cleanLine.contains("Operation not permitted") {
                    capturedError = cleanLine
                }
            }
        } catch {
            print("Playlist-Stream Fehler: \(error)")
        }

        process.waitUntilExit()
        let exitCode = process.terminationStatus

        self.isDownloading = false

        if self.isCancelled {
            self.statusText = "Playlist-Download abgebrochen"
            self.errorMessage = "Download wurde vom Benutzer abgebrochen."
            return
        }

        if exitCode == 0 {
            self.percent = 100.0
            self.statusText = "Playlist-Download erfolgreich abgeschlossen (100%)"
            self.etaText = "Fertiggestellt"
            self.detailsText = "Gespeichert in: \(targetFolder.path)"
            self.finishedFilePath = targetFolder.path

            HistoryManager.shared.add(item: DownloadHistoryItem(
                title: playlist.title,
                uploader: playlist.uploader,
                thumbnailURL: playlist.thumbnailURL?.absoluteString,
                filePath: targetFolder.path,
                formatDisplay: "\(format.display) • \(totalItemsCount) Dateien",
                platform: platform.rawValue
            ))

            NotificationService.shared.notifyDownloadFinished(title: "Playlist: \(playlist.title)", filePath: targetFolder.path)
        } else {
            if useCookies && (capturedError.contains("Operation not permitted") || capturedError.lowercased().contains("cookies")) {
                print("Playlist-Download mit Cookies fehlgeschlagen, wiederhole ohne...")
                Task {
                    await self.executePlaylistDownload(
                        playlist: playlist,
                        selectedIndices: selectedIndices,
                        format: format,
                        outputFolder: outputFolder,
                        platform: platform,
                        createSubfolder: createSubfolder,
                        numberFiles: numberFiles,
                        useCookies: false
                    )
                }
                return
            }
            self.statusText = "Playlist-Download mit Fehlern beendet"
            self.errorMessage = capturedError.isEmpty ? "Prozess beendet mit Code \(exitCode)" : capturedError
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\":<>")
        let clean = name.components(separatedBy: invalid).joined(separator: "-")
        let trimmed = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Playlist" : trimmed
    }

    public func convertCurrentFileToH265() {
        guard let path = finishedFilePath, FileManager.default.fileExists(atPath: path), !isDownloading, !isConverting else { return }
        self.isConverting = true
        self.isCancelled = false
        self.percent = 0.0
        self.statusText = "Wird in H.265 (HEVC) umgewandelt..."
        self.detailsText = "Apple Silicon VideoToolbox Hardware-Encoding..."
        self.etaText = "Berechne..."

        Task {
            if let newPath = await self.convertFileToH265(inputPath: path) {
                await MainActor.run {
                    self.finishedFilePath = newPath
                    self.isConverting = false
                    self.percent = 100.0
                    self.statusText = "H.265-Konvertierung erfolgreich abgeschlossen!"
                    self.detailsText = "Gespeichert als: \(URL(fileURLWithPath: newPath).lastPathComponent)"
                    self.etaText = "Fertiggestellt"
                }
            } else {
                await MainActor.run {
                    self.isConverting = false
                    if !self.isCancelled {
                        self.statusText = "H.265-Konvertierung fehlgeschlagen."
                        self.errorMessage = "Konnte Datei nicht mit FFmpeg in H.265 umwandeln."
                    } else {
                        self.statusText = "H.265-Konvertierung abgebrochen."
                    }
                }
            }
        }
    }

    private func convertFileToH265(inputPath: String) async -> String? {
        guard let ffmpegPath = ProcessHelper.findFFmpeg() else {
            print("FFmpeg nicht gefunden für H.265 Konvertierung")
            return nil
        }

        let totalDuration = ProcessHelper.getVideoDuration(filePath: inputPath)

        let inputURL = URL(fileURLWithPath: inputPath)
        let dir = inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent
        let outputURL = dir.appendingPathComponent("\(baseName) [H265].mp4")
        let outputPath = outputURL.path

        // First attempt with Apple Silicon hardware encoder: hevc_videotoolbox
        let success = await runFFmpegConversion(
            ffmpegPath: ffmpegPath,
            input: inputPath,
            output: outputPath,
            videoCodec: "hevc_videotoolbox",
            totalDuration: totalDuration
        )

        if isCancelled {
            try? FileManager.default.removeItem(atPath: outputPath)
            return nil
        }

        if success && FileManager.default.fileExists(atPath: outputPath) {
            try? FileManager.default.removeItem(atPath: inputPath)
            return outputPath
        }

        // Fallback to libx265 if videotoolbox had an issue
        let fallbackSuccess = await runFFmpegConversion(
            ffmpegPath: ffmpegPath,
            input: inputPath,
            output: outputPath,
            videoCodec: "libx265",
            totalDuration: totalDuration
        )

        if isCancelled {
            try? FileManager.default.removeItem(atPath: outputPath)
            return nil
        }

        if fallbackSuccess && FileManager.default.fileExists(atPath: outputPath) {
            try? FileManager.default.removeItem(atPath: inputPath)
            return outputPath
        }

        return nil
    }

    private final class ConversionProgressTracker: @unchecked Sendable {
        private var speed: Double = 1.0
        private let totalDuration: Double
        private let onUpdate: @Sendable (Double, String, String) -> Void

        init(totalDuration: Double, onUpdate: @escaping @Sendable (Double, String, String) -> Void) {
            self.totalDuration = totalDuration
            self.onUpdate = onUpdate
        }

        func processLine(_ line: String) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.starts(with: "out_time_us=") {
                let valStr = trimmed.replacingOccurrences(of: "out_time_us=", with: "")
                if let us = Double(valStr), totalDuration > 0 {
                    let curSec = us / 1_000_000.0
                    let pct = min(99.0, max(0.0, (curSec / totalDuration) * 100.0))
                    let remainingSec = max(0.0, (totalDuration - curSec) / max(0.5, speed))
                    let eta = formatFriendlyETA(seconds: Int(remainingSec))
                    let details = String(format: "%.1fx Geschwindigkeit • H.265 Hardware-Encoding", speed)
                    onUpdate(pct, eta, details)
                }
            } else if trimmed.starts(with: "speed=") {
                let spdStr = trimmed.replacingOccurrences(of: "speed=", with: "").replacingOccurrences(of: "x", with: "")
                if let spd = Double(spdStr), spd > 0 {
                    speed = spd
                }
            } else if trimmed == "progress=end" {
                onUpdate(100.0, "Fertiggestellt", "Konvertierung abgeschlossen")
            }
        }
    }

    private func runFFmpegConversion(
        ffmpegPath: String,
        input: String,
        output: String,
        videoCodec: String,
        totalDuration: Double
    ) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        var args = [
            "-y",
            "-i", input,
            "-c:v", videoCodec
        ]
        if videoCodec == "hevc_videotoolbox" {
            args += ["-q:v", "65", "-tag:v", "hvc1"]
        } else {
            args += ["-crf", "23", "-tag:v", "hvc1"]
        }
        args += [
            "-c:a", "copy",
            "-progress", "pipe:1",
            output
        ]

        process.arguments = args
        process.environment = ProcessHelper.makeEnvironment()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        self.currentProcess = process

        let tracker = ConversionProgressTracker(totalDuration: totalDuration) { [weak self] pct, eta, details in
            Task { @MainActor in
                self?.percent = pct
                self?.etaText = eta
                self?.detailsText = details
            }
        }

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            for line in text.components(separatedBy: "\n") {
                tracker.processLine(line)
            }
        }

        return await Task.detached(priority: .userInitiated) { () -> Bool in
            do {
                try process.run()
                process.waitUntilExit()
                pipe.fileHandleForReading.readabilityHandler = nil
                return process.terminationStatus == 0
            } catch {
                pipe.fileHandleForReading.readabilityHandler = nil
                return false
            }
        }.value
    }

    public func revealInFinder() {
        if let path = finishedFilePath, FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        } else if let path = finishedFilePath {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
        }
    }

    public func openFile() {
        if let path = finishedFilePath, FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }
}
