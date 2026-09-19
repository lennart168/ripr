import Foundation

public enum Platform: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"
    case twitter = "X (Twitter)"
    case reddit = "Reddit"
    case twitch = "Twitch"
    case kick = "Kick"
    case rumble = "Rumble"
    case facebook = "Facebook"
    case pinterest = "Pinterest"
    case vimeo = "Vimeo"
    case soundcloud = "SoundCloud"
    case daserste = "ARD Mediathek"
    case zdf = "ZDF Mediathek"
    case universal = "Universal Web"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .auto: return "sparkles"
        case .youtube: return "play.rectangle.fill"
        case .tiktok: return "music.note"
        case .instagram: return "camera.fill"
        case .twitter: return "bubble.left.and.bubble.right.fill"
        case .reddit: return "text.bubble.fill"
        case .twitch: return "tv.fill"
        case .kick: return "play.fill"
        case .rumble: return "play.rectangle"
        case .facebook: return "hand.thumbsup.fill"
        case .pinterest: return "pin.fill"
        case .vimeo: return "play.circle.fill"
        case .soundcloud: return "waveform"
        case .daserste: return "tv"
        case .zdf: return "tv.and.mediabox"
        case .universal: return "globe"
        }
    }

    public var placeholder: String {
        switch self {
        case .auto:
            return "Link einfügen (YouTube, TikTok etc.)"
        case .youtube:
            return "YouTube Video- oder Shorts-URL einfügen"
        case .tiktok:
            return "TikTok Video-URL einfügen"
        case .instagram:
            return "Instagram Reel- oder Post-URL einfügen"
        case .twitter:
            return "X / Twitter Tweet- oder Video-URL einfügen"
        case .reddit:
            return "Reddit Post- oder Video-URL einfügen"
        case .twitch:
            return "Twitch Clip- oder VOD-URL einfügen"
        case .kick:
            return "Kick Live-Stream- oder Clip-URL einfügen"
        case .rumble:
            return "Rumble Video-URL einfügen"
        case .facebook:
            return "Facebook Video-URL einfügen"
        case .pinterest:
            return "Pinterest Pin-URL einfügen"
        case .vimeo:
            return "Vimeo Video-URL einfügen"
        case .soundcloud:
            return "SoundCloud Track-URL einfügen"
        case .daserste:
            return "ARD Mediathek Video-URL einfügen"
        case .zdf:
            return "ZDF Mediathek Video-URL einfügen"
        case .universal:
            return "Beliebige Video- oder Audio-URL einfügen"
        }
    }

    public var headline: String {
        switch self {
        case .auto: return "Smart Auto-Erkennung"
        case .youtube: return "YouTube Downloader"
        case .tiktok: return "TikTok Downloader"
        case .instagram: return "Instagram Downloader"
        case .twitter: return "X (Twitter) Downloader"
        case .reddit: return "Reddit Downloader"
        case .twitch: return "Twitch Downloader"
        case .kick: return "Kick Downloader"
        case .rumble: return "Rumble Downloader"
        case .facebook: return "Facebook Downloader"
        case .pinterest: return "Pinterest Downloader"
        case .vimeo: return "Vimeo Downloader"
        case .soundcloud: return "SoundCloud Downloader"
        case .daserste: return "ARD Mediathek Downloader"
        case .zdf: return "ZDF Mediathek Downloader"
        case .universal: return "Universal Web Downloader"
        }
    }

    public var subheadline: String {
        switch self {
        case .auto:
            return "Füge einen beliebigen Link ein – die Plattform wird automatisch erkannt."
        case .youtube:
            return "Lade YouTube Videos & Shorts in bis zu 4K herunter oder extrahiere Audio als MP3."
        case .tiktok:
            return "Lade TikToks ohne Wasserzeichen in Originalqualität oder als Sounddatei herunter."
        case .instagram:
            return "Lade Instagram Reels, Videos, Stories und Posts in voller Qualität herunter."
        case .twitter:
            return "Lade Videos, Clips und GIFs von X / Twitter in höchster Qualität herunter."
        case .reddit:
            return "Lade Reddit-Videos inklusive Ton und nativer Audiospur herunter."
        case .twitch:
            return "Lade Clips, komplette VODs herunter oder nimm laufende Streams auf."
        case .kick:
            return "Lade Kick Live-Streams, VODs und Clips in bester 1080p60 Qualität herunter."
        case .rumble:
            return "Lade Rumble Videos und Streams in voller Qualität herunter."
        case .facebook:
            return "Lade Facebook Videos, Watch-Clips und Reels in HD herunter."
        case .pinterest:
            return "Lade Pinterest Video-Pins und Story-Pins in Originalqualität herunter."
        case .vimeo:
            return "Lade Vimeo Videos in 1080p, 4K oder Original-Masterqualität herunter."
        case .soundcloud:
            return "Lade SoundCloud Tracks und Musikstücke als hochwertige MP3 herunter."
        case .daserste:
            return "Lade Sendungen, Filme und Dokus der ARD Mediathek in bester HD-Qualität herunter."
        case .zdf:
            return "Lade Beiträge, Dokus und Filme der ZDF Mediathek direkt herunter."
        case .universal:
            return "Lade Videos von über 1.800+ Webseiten (Mediatheken, Web-Videos etc.) herunter."
        }
    }

    public static func detect(from urlString: String) -> Platform {
        let lower = urlString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.contains("youtube.com") || lower.contains("youtu.be") {
            return .youtube
        } else if lower.contains("tiktok.com") {
            return .tiktok
        } else if lower.contains("instagram.com") {
            return .instagram
        } else if lower.contains("twitter.com") || lower.contains("x.com") || lower.contains("t.co") {
            return .twitter
        } else if lower.contains("reddit.com") || lower.contains("redd.it") {
            return .reddit
        } else if lower.contains("twitch.tv") {
            return .twitch
        } else if lower.contains("kick.com") {
            return .kick
        } else if lower.contains("rumble.com") {
            return .rumble
        } else if lower.contains("facebook.com") || lower.contains("fb.watch") || lower.contains("fb.com") {
            return .facebook
        } else if lower.contains("pinterest.com") || lower.contains("pin.it") {
            return .pinterest
        } else if lower.contains("vimeo.com") {
            return .vimeo
        } else if lower.contains("soundcloud.com") {
            return .soundcloud
        } else if lower.contains("daserste.de") || lower.contains("ardmediathek.de") || lower.contains("ard.de") {
            return .daserste
        } else if lower.contains("zdf.de") {
            return .zdf
        } else {
            return .universal
        }
    }
}

public struct FormatOption: Identifiable, Hashable {
    public let id = UUID()
    public let display: String
    public let selector: String
    public let height: Int
    public let isAudioOnly: Bool
    public let formatExt: String
    public let estimatedSizeFormatted: String?

    public init(display: String, selector: String, height: Int = 0, isAudioOnly: Bool = false, formatExt: String = "mp4", estimatedSizeFormatted: String? = nil) {
        self.display = display
        self.selector = selector
        self.height = height
        self.isAudioOnly = isAudioOnly
        self.formatExt = formatExt
        self.estimatedSizeFormatted = estimatedSizeFormatted
    }
}

public struct VideoMetadata: Identifiable {
    public let id: String
    public let title: String
    public let thumbnailURL: URL?
    public let durationSeconds: Int
    public let durationFormatted: String
    public let uploader: String
    public let viewCount: Int?
    public let viewCountFormatted: String?
    public let estimatedFileSize: Int64?
    public let estimatedFileSizeFormatted: String?
    public let isLive: Bool
    public let videoOptions: [FormatOption]
    public let audioOptions: [FormatOption]

    public init(
        id: String,
        title: String,
        thumbnailURL: URL?,
        durationSeconds: Int,
        uploader: String,
        viewCount: Int? = nil,
        estimatedFileSize: Int64? = nil,
        isLive: Bool,
        videoOptions: [FormatOption],
        audioOptions: [FormatOption]
    ) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.durationSeconds = durationSeconds
        self.uploader = uploader
        self.viewCount = viewCount
        self.estimatedFileSize = estimatedFileSize
        self.isLive = isLive
        self.videoOptions = videoOptions
        self.audioOptions = audioOptions

        if let vc = viewCount, vc > 0 {
            if vc >= 1_000_000 {
                let m = Double(vc) / 1_000_000.0
                let formatted = String(format: "%.1f", m)
                self.viewCountFormatted = "\(formatted.hasSuffix(".0") ? String(formatted.dropLast(2)) : formatted) Mio. Aufrufe"
            } else if vc >= 10_000 {
                self.viewCountFormatted = "\(vc / 1_000) Tsd. Aufrufe"
            } else if vc >= 1_000 {
                let k = Double(vc) / 1_000.0
                let formatted = String(format: "%.1f", k)
                self.viewCountFormatted = "\(formatted.hasSuffix(".0") ? String(formatted.dropLast(2)) : formatted) Tsd. Aufrufe"
            } else {
                self.viewCountFormatted = "\(vc) Aufrufe"
            }
        } else {
            self.viewCountFormatted = nil
        }

        if let size = estimatedFileSize, size > 0 {
            let gb = Double(size) / 1_073_741_824.0
            let mb = Double(size) / 1_048_576.0
            if gb >= 1.0 {
                self.estimatedFileSizeFormatted = String(format: "ca. %.1f GB", gb)
            } else {
                self.estimatedFileSizeFormatted = String(format: "ca. %.0f MB", mb)
            }
        } else {
            self.estimatedFileSizeFormatted = nil
        }

        if isLive {
            self.durationFormatted = "Live"
        } else if durationSeconds > 0 {
            let m = durationSeconds / 60
            let s = durationSeconds % 60
            let h = m / 60
            let remM = m % 60
            if h > 0 {
                self.durationFormatted = String(format: "%d:%02d:%02d", h, remM, s)
            } else {
                self.durationFormatted = String(format: "%d:%02d", remM, s)
            }
        } else {
            self.durationFormatted = ""
        }
    }
}

public func formatFriendlyETA(_ etaStr: String) -> String {
    let clean = etaStr.trimmingCharacters(in: .whitespacesAndNewlines)
    if clean.isEmpty || clean == "Unknown" || clean == "NA" || clean == "--:--" {
        return "Berechne Restzeit..."
    }
    let parts = clean.split(separator: ":").map { String($0) }
    if parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) {
        if m == 0 {
            return "Noch ca. \(s) Sekunden"
        } else if m == 1 {
            return "Noch ca. 1 Min \(s) Sek"
        } else {
            return String(format: "Noch ca. %d Min %02d Sek", m, s)
        }
    } else if parts.count == 3, let h = Int(parts[0]), let m = Int(parts[1]) {
        return "Noch ca. \(h) Std \(m) Min"
    }
    return "Noch ca. \(clean)"
}

public func formatFriendlyETA(seconds: Int) -> String {
    if seconds <= 0 {
        return "Gleich fertig..."
    }
    let m = seconds / 60
    let s = seconds % 60
    let h = m / 60
    let remM = m % 60
    if h > 0 {
        return "Noch ca. \(h) Std \(remM) Min"
    } else if m > 0 {
        return String(format: "Noch ca. %d Min %02d Sek", m, s)
    } else {
        return "Noch ca. \(s) Sekunden"
    }
}
