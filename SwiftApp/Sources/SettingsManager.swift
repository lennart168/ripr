import Foundation
import Combine

public final class SettingsManager: ObservableObject {
    public static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    @Published public var downloadFolder: URL {
        didSet { defaults.set(downloadFolder.path, forKey: "downloadFolderPath") }
    }

    @Published public var cookieBrowser: String {
        didSet { defaults.set(cookieBrowser, forKey: "cookieBrowser") }
    }

    @Published public var cookieFilePath: String {
        didSet { defaults.set(cookieFilePath, forKey: "cookieFilePath") }
    }

    @Published public var useCookiesInstagram: Bool {
        didSet { defaults.set(useCookiesInstagram, forKey: "useCookiesInstagram") }
    }

    @Published public var useCookiesYouTube: Bool {
        didSet { defaults.set(useCookiesYouTube, forKey: "useCookiesYouTube") }
    }

    @Published public var useCookiesTwitch: Bool {
        didSet { defaults.set(useCookiesTwitch, forKey: "useCookiesTwitch") }
    }

    @Published public var useCookiesUniversal: Bool {
        didSet { defaults.set(useCookiesUniversal, forKey: "useCookiesUniversal") }
    }

    @Published public var embedThumbnail: Bool {
        didSet { defaults.set(embedThumbnail, forKey: "embedThumbnail") }
    }

    @Published public var embedMetadata: Bool {
        didSet { defaults.set(embedMetadata, forKey: "embedMetadata") }
    }

    @Published public var convertToH265: Bool {
        didSet { defaults.set(convertToH265, forKey: "convertToH265") }
    }

    @Published public var autoUpdateYtDlp: Bool {
        didSet { defaults.set(autoUpdateYtDlp, forKey: "autoUpdateYtDlp") }
    }

    @Published public var autoCheckAppUpdates: Bool {
        didSet { defaults.set(autoCheckAppUpdates, forKey: "autoCheckAppUpdates") }
    }

    @Published public var autoDownloadAppUpdates: Bool {
        didSet { defaults.set(autoDownloadAppUpdates, forKey: "autoDownloadAppUpdates") }
    }

    @Published public var sendDownloadNotification: Bool {
        didSet { defaults.set(sendDownloadNotification, forKey: "sendDownloadNotification") }
    }

    private init() {
        let defaultDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")

        if let savedPath = defaults.string(forKey: "downloadFolderPath"), !savedPath.isEmpty {
            self.downloadFolder = URL(fileURLWithPath: savedPath)
        } else {
            self.downloadFolder = defaultDir
        }

        self.cookieBrowser = defaults.string(forKey: "cookieBrowser") ?? "none"
        self.cookieFilePath = defaults.string(forKey: "cookieFilePath") ?? ""

        // Standard-Werte für Plattformen
        if defaults.object(forKey: "useCookiesInstagram") != nil {
            self.useCookiesInstagram = defaults.bool(forKey: "useCookiesInstagram")
        } else {
            self.useCookiesInstagram = true
        }

        self.useCookiesYouTube = defaults.bool(forKey: "useCookiesYouTube") // Default false
        self.useCookiesTwitch = defaults.bool(forKey: "useCookiesTwitch")
        self.useCookiesUniversal = defaults.bool(forKey: "useCookiesUniversal")

        if defaults.object(forKey: "embedThumbnail") != nil {
            self.embedThumbnail = defaults.bool(forKey: "embedThumbnail")
        } else {
            self.embedThumbnail = true
        }

        if defaults.object(forKey: "embedMetadata") != nil {
            self.embedMetadata = defaults.bool(forKey: "embedMetadata")
        } else {
            self.embedMetadata = true
        }

        self.convertToH265 = defaults.bool(forKey: "convertToH265") // Default false

        if defaults.object(forKey: "autoUpdateYtDlp") != nil {
            self.autoUpdateYtDlp = defaults.bool(forKey: "autoUpdateYtDlp")
        } else {
            self.autoUpdateYtDlp = true // Standardmäßig aktiviert
        }

        if defaults.object(forKey: "autoCheckAppUpdates") != nil {
            self.autoCheckAppUpdates = defaults.bool(forKey: "autoCheckAppUpdates")
        } else {
            self.autoCheckAppUpdates = true
        }

        if defaults.object(forKey: "autoDownloadAppUpdates") != nil {
            self.autoDownloadAppUpdates = defaults.bool(forKey: "autoDownloadAppUpdates")
        } else {
            self.autoDownloadAppUpdates = true
        }

        if defaults.object(forKey: "sendDownloadNotification") != nil {
            self.sendDownloadNotification = defaults.bool(forKey: "sendDownloadNotification")
        } else {
            self.sendDownloadNotification = true
        }
    }

    public func getCookieArgs(for platform: Platform) -> [String] {
        guard cookieBrowser != "none" || !cookieFilePath.isEmpty else { return [] }

        let shouldApply: Bool
        switch platform {
        case .instagram: shouldApply = useCookiesInstagram
        case .youtube: shouldApply = useCookiesYouTube
        case .twitch: shouldApply = useCookiesTwitch
        case .tiktok, .auto: shouldApply = false
        case .twitter, .reddit, .kick, .rumble, .facebook, .pinterest, .vimeo, .soundcloud, .daserste, .zdf, .universal:
            shouldApply = useCookiesUniversal
        }

        guard shouldApply else { return [] }

        if cookieBrowser == "custom_file" && !cookieFilePath.isEmpty {
            if FileManager.default.fileExists(atPath: cookieFilePath) {
                return ["--cookiefile", cookieFilePath]
            }
        } else if ["chrome", "firefox", "safari", "brave", "edge"].contains(cookieBrowser) {
            return ["--cookies-from-browser", cookieBrowser]
        }
        return []
    }
}
