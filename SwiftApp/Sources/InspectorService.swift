import Foundation

public final class InspectorService {
    public static func inspect(url: String, platform: Platform) async throws -> InspectionResult {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaylistOnly = trimmed.contains("playlist?list=") ||
                             (!trimmed.contains("v=") && trimmed.contains("list=")) ||
                             trimmed.contains("/sets/") ||
                             trimmed.contains("/albums/")
        let isCombo = !isPlaylistOnly && trimmed.contains("list=") && (trimmed.contains("v=") || trimmed.contains("watch") || trimmed.contains("youtu.be"))

        if isCombo {
            // Kombi-Link: Extrahiere sowohl das Video als auch die Playlist parallel
            do {
                async let videoTask = fetchDumpJson(url: trimmed, platform: platform, useCookies: true, forceNoPlaylist: true)
                async let playlistTask = fetchDumpJson(url: trimmed, platform: platform, useCookies: true, forceNoPlaylist: false)
                let (videoJson, playlistJson) = try await (videoTask, playlistTask)

                let videoMeta = parseVideoMetadata(videoJson)
                var playlistMeta: PlaylistMetadata? = nil
                if let pType = playlistJson["_type"] as? String, pType == "playlist" {
                    playlistMeta = parsePlaylistMetadata(playlistJson, originalURL: trimmed)
                }
                return .video(videoMeta, associatedPlaylist: playlistMeta)
            } catch {
                let videoJson = try await fetchDumpJson(url: trimmed, platform: platform, useCookies: false, forceNoPlaylist: true)
                let videoMeta = parseVideoMetadata(videoJson)
                return .video(videoMeta, associatedPlaylist: nil)
            }
        } else if isPlaylistOnly {
            // Reine Playlist
            do {
                let json = try await fetchDumpJson(url: trimmed, platform: platform, useCookies: true, forceNoPlaylist: false)
                let playlistMeta = parsePlaylistMetadata(json, originalURL: trimmed)
                return .playlist(playlistMeta)
            } catch {
                let json = try await fetchDumpJson(url: trimmed, platform: platform, useCookies: false, forceNoPlaylist: false)
                let playlistMeta = parsePlaylistMetadata(json, originalURL: trimmed)
                return .playlist(playlistMeta)
            }
        } else {
            // Normales Einzelvideo oder Universal
            do {
                let json = try await fetchDumpJson(url: trimmed, platform: platform, useCookies: true, forceNoPlaylist: false)
                if let pType = json["_type"] as? String, pType == "playlist" {
                    let playlistMeta = parsePlaylistMetadata(json, originalURL: trimmed)
                    return .playlist(playlistMeta)
                } else {
                    let videoMeta = parseVideoMetadata(json)
                    return .video(videoMeta, associatedPlaylist: nil)
                }
            } catch {
                let json = try await fetchDumpJson(url: trimmed, platform: platform, useCookies: false, forceNoPlaylist: true)
                if let pType = json["_type"] as? String, pType == "playlist" {
                    let playlistMeta = parsePlaylistMetadata(json, originalURL: trimmed)
                    return .playlist(playlistMeta)
                } else {
                    let videoMeta = parseVideoMetadata(json)
                    return .video(videoMeta, associatedPlaylist: nil)
                }
            }
        }
    }

    public static func inspectVideoOnly(url: String, platform: Platform) async throws -> VideoMetadata {
        let result = try await inspect(url: url, platform: platform)
        switch result {
        case .video(let video, _):
            return video
        case .playlist(let playlist):
            return VideoMetadata(
                id: playlist.id,
                title: playlist.title,
                thumbnailURL: playlist.thumbnailURL,
                durationSeconds: 0,
                uploader: playlist.uploader,
                viewCount: nil,
                estimatedFileSize: nil,
                isLive: false,
                videoOptions: PlaylistFormatPresets.videoOptions,
                audioOptions: PlaylistFormatPresets.audioOptions
            )
        }
    }

    private static func fetchDumpJson(url: String, platform: Platform, useCookies: Bool, forceNoPlaylist: Bool) async throws -> [String: Any] {
        let (ytdlpPath, isPythonModule) = ProcessHelper.findYtDlp()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)

        var args: [String] = []
        if isPythonModule {
            args.append(contentsOf: ["-m", "yt_dlp"])
        }
        args.append(contentsOf: [
            "--dump-single-json",
            "--flat-playlist",
            "--no-warnings",
            "--remote-components", "ejs:github"
        ])

        if forceNoPlaylist {
            args.append("--no-playlist")
        } else {
            args.append("--yes-playlist")
        }

        if useCookies {
            let cookieArgs = SettingsManager.shared.getCookieArgs(for: platform)
            args.append(contentsOf: cookieArgs)
        }

        args.append(url)
        process.arguments = args
        process.environment = ProcessHelper.makeEnvironment()

        let pipeOut = Pipe()
        let pipeErr = Pipe()
        process.standardOutput = pipeOut
        process.standardError = pipeErr

        try process.run()

        let data = pipeOut.fileHandleForReading.readDataToEndOfFile()
        let errData = pipeErr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errStr = String(data: errData, encoding: .utf8) ?? "Unbekannter Fehler bei yt-dlp"
            throw NSError(domain: "InspectorService", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errStr])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "InspectorService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Konnte Metadaten-JSON nicht analysieren"])
        }

        return json
    }

    private static func parsePlaylistMetadata(_ json: [String: Any], originalURL: String) -> PlaylistMetadata {
        let id = json["id"] as? String ?? UUID().uuidString
        let title = json["title"] as? String ?? "Playlist"
        let uploader = (json["uploader"] as? String)
            ?? (json["channel"] as? String)
            ?? (json["creator"] as? String)
            ?? "Unbekannter Ersteller"

        var thumbURL: URL? = nil
        if let thumbStr = json["thumbnail"] as? String {
            thumbURL = URL(string: thumbStr)
        } else if let thumbs = json["thumbnails"] as? [[String: Any]], let lastThumb = thumbs.last?["url"] as? String {
            thumbURL = URL(string: lastThumb)
        }

        let rawEntries = json["entries"] as? [[String: Any]] ?? []
        var items: [PlaylistItem] = []

        for (i, entry) in rawEntries.enumerated() {
            let itemId = entry["id"] as? String ?? "\(i + 1)"
            let itemTitle = entry["title"] as? String ?? "Element \(i + 1)"
            let itemDuration = entry["duration"] as? Int ?? 0
            let itemUploader = (entry["uploader"] as? String) ?? (entry["channel"] as? String) ?? uploader

            var itemThumb: URL? = nil
            if let t = entry["thumbnail"] as? String {
                itemThumb = URL(string: t)
            } else if let thumbs = entry["thumbnails"] as? [[String: Any]], let first = thumbs.first?["url"] as? String {
                itemThumb = URL(string: first)
            }

            let itemUrl = entry["url"] as? String
                ?? entry["webpage_url"] as? String
                ?? "https://www.youtube.com/watch?v=\(itemId)"

            let item = PlaylistItem(
                id: itemId,
                index: i + 1,
                title: itemTitle,
                durationSeconds: itemDuration,
                uploader: itemUploader,
                thumbnailURL: itemThumb ?? thumbURL,
                url: itemUrl
            )
            items.append(item)
        }

        let count = json["playlist_count"] as? Int ?? items.count

        return PlaylistMetadata(
            id: id,
            title: title,
            uploader: uploader,
            thumbnailURL: thumbURL ?? items.first?.thumbnailURL,
            itemCount: max(count, items.count),
            items: items,
            webpageURL: originalURL
        )
    }

    private static func parseVideoMetadata(_ json: [String: Any]) -> VideoMetadata {
        let id = json["id"] as? String ?? UUID().uuidString
        let title = json["title"] as? String ?? "Unbekannter Titel"
        let thumb = (json["thumbnail"] as? String).flatMap { URL(string: $0) }
        let duration = json["duration"] as? Int ?? 0
        let uploader = (json["uploader"] as? String)
            ?? (json["channel"] as? String)
            ?? (json["creator"] as? String)
            ?? "Unbekannter Kanal"

        let isLive = (json["is_live"] as? Bool) ?? (json["live_status"] as? String == "is_live")

        let viewCount = json["view_count"] as? Int
            ?? (json["view_count"] as? Double).map { Int($0) }
            ?? (json["view_count"] as? String).flatMap { Int($0) }

        var estSize: Int64? = nil
        if let fs = json["filesize_approx"] as? Int64 ?? json["filesize"] as? Int64 {
            estSize = fs
        } else if let fs = json["filesize_approx"] as? Int ?? json["filesize"] as? Int {
            estSize = Int64(fs)
        } else if let fs = json["filesize_approx"] as? Double ?? json["filesize"] as? Double {
            estSize = Int64(fs)
        }

        if estSize == nil, let formats = json["formats"] as? [[String: Any]] {
            var maxTbr: Double = 0
            for f in formats {
                if let tbr = f["tbr"] as? Double, tbr > maxTbr {
                    maxTbr = tbr
                } else if let tbr = f["tbr"] as? Int, Double(tbr) > maxTbr {
                    maxTbr = Double(tbr)
                }
            }
            if maxTbr > 0 && duration > 0 {
                estSize = Int64(maxTbr * 125.0 * Double(duration))
            }
        }

        var videoOpts: [FormatOption] = []
        let audioOpts: [FormatOption] = [
            FormatOption(display: "MP3 (320 kbps — Höchste Qualität)", selector: "bestaudio/best", isAudioOnly: true, formatExt: "mp3"),
            FormatOption(display: "M4A / AAC (Apple & Mac)", selector: "bestaudio/best", isAudioOnly: true, formatExt: "m4a"),
            FormatOption(display: "FLAC (Lossless / Verlustfrei)", selector: "bestaudio/best", isAudioOnly: true, formatExt: "flac"),
            FormatOption(display: "WAV (Unkomprimiert)", selector: "bestaudio/best", isAudioOnly: true, formatExt: "wav"),
            FormatOption(display: "OPUS (Original Web)", selector: "bestaudio/best", isAudioOnly: true, formatExt: "opus")
        ]

        if isLive {
            // Live Stream Formate
            if let formats = json["formats"] as? [[String: Any]] {
                for f in formats {
                    let height = f["height"] as? Int ?? 0
                    let fps = (f["fps"] as? Double) ?? 0
                    let formatId = f["format_id"] as? String ?? "best"
                    let note = f["format_note"] as? String ?? ""

                    var label = height > 0 ? "\(height)p" : formatId
                    if fps > 30 { label += "\(Int(fps))" }
                    if !note.isEmpty { label += " (\(note))" }

                    videoOpts.append(FormatOption(
                        display: label,
                        selector: formatId,
                        height: height,
                        isAudioOnly: false,
                        formatExt: "mp4"
                    ))
                }
            }
            videoOpts.sort(by: { $0.height > $1.height })
            videoOpts.insert(FormatOption(
                display: "Beste Live-Qualität (Quelle / Source)",
                selector: "best",
                height: 99999,
                isAudioOnly: false,
                formatExt: "mp4"
            ), at: 0)
        } else {
            // Reguläre Videos
            var seenCombos = Set<String>()
            if let formats = json["formats"] as? [[String: Any]] {
                for f in formats {
                    let vcodec = (f["vcodec"] as? String) ?? "none"
                    if vcodec == "none" { continue }

                    guard let height = f["height"] as? Int, height >= 144 else { continue }
                    let fps = (f["fps"] as? Double) ?? 30
                    let fpsStr = fps > 30 ? " \(Int(fps))fps" : ""

                    var codecClean = "Andere"
                    var vcodecFilter = ""
                    let vlower = vcodec.lowercased()
                    if vlower.hasPrefix("avc1") || vlower.contains("h264") {
                        codecClean = "H.264"
                        vcodecFilter = "[vcodec^=avc1]"
                    } else if vlower.hasPrefix("vp9") || vlower.hasPrefix("vp09") {
                        codecClean = "VP9"
                        vcodecFilter = "[vcodec^=vp09]"
                    } else if vlower.hasPrefix("av01") || vlower.contains("av1") {
                        codecClean = "AV1"
                        vcodecFilter = "[vcodec^=av01]"
                    } else if vlower.contains("h265") || vlower.hasPrefix("hev") {
                        codecClean = "H.265"
                    }

                    var resLabel = "\(height)p"
                    if height >= 2160 { resLabel += " (4K UHD)" }
                    else if height >= 1440 { resLabel += " (2K QHD)" }
                    else if height >= 1080 { resLabel += " (Full HD)" }
                    else if height >= 720 { resLabel += " (HD)" }

                    var optSizeStr: String? = nil
                    if let fsize = f["filesize"] as? Int64 ?? f["filesize_approx"] as? Int64 {
                        let mb = Double(fsize) / 1_048_576.0
                        optSizeStr = mb >= 1000 ? String(format: "ca. %.1f GB", mb / 1024.0) : String(format: "ca. %.0f MB", mb)
                    } else if let tbr = (f["tbr"] as? Double) ?? (f["tbr"] as? Int).map(Double.init), tbr > 0, duration > 0 {
                        let mb = (tbr * 125.0 * Double(duration)) / 1_048_576.0
                        optSizeStr = mb >= 1000 ? String(format: "ca. %.1f GB", mb / 1024.0) : String(format: "ca. %.0f MB", mb)
                    }

                    let comboKey = "\(height)-\(codecClean)"
                    if !seenCombos.contains(comboKey) {
                        seenCombos.insert(comboKey)

                        let selector = "bestvideo[height<=\(height)]\(vcodecFilter)+bestaudio/best[height<=\(height)]/best"
                        var display = "\(resLabel)\(fpsStr) — \(codecClean)"
                        if let s = optSizeStr {
                            display += " (\(s))"
                        }

                        videoOpts.append(FormatOption(
                            display: display,
                            selector: selector,
                            height: height,
                            isAudioOnly: false,
                            formatExt: "mp4",
                            estimatedSizeFormatted: optSizeStr
                        ))
                    }
                }
            }

            videoOpts.sort(by: {
                if $0.height != $1.height {
                    return $0.height > $1.height
                }
                return $0.display.contains("H.264")
            })
            videoOpts.insert(FormatOption(
                display: "Beste verfügbare Qualität (Automatisch)",
                selector: "bestvideo+bestaudio/best",
                height: 99999,
                isAudioOnly: false,
                formatExt: "mp4",
                estimatedSizeFormatted: nil
            ), at: 0)
        }

        return VideoMetadata(
            id: id,
            title: title,
            thumbnailURL: thumb,
            durationSeconds: duration,
            uploader: uploader,
            viewCount: viewCount,
            estimatedFileSize: estSize,
            isLive: isLive,
            videoOptions: videoOpts,
            audioOptions: audioOpts
        )
    }
}
