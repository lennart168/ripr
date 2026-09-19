import Foundation
import AppKit
import Combine

public struct DownloadHistoryItem: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let uploader: String
    public let thumbnailURL: String?
    public let filePath: String
    public let formatDisplay: String
    public let platform: String
    public let downloadDate: Date

    public init(
        id: UUID = UUID(),
        title: String,
        uploader: String,
        thumbnailURL: String?,
        filePath: String,
        formatDisplay: String,
        platform: String,
        downloadDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.uploader = uploader
        self.thumbnailURL = thumbnailURL
        self.filePath = filePath
        self.formatDisplay = formatDisplay
        self.platform = platform
        self.downloadDate = downloadDate
    }

    public var fileExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    public var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: downloadDate)
    }
}

@MainActor
public final class HistoryManager: ObservableObject {
    public static let shared = HistoryManager()

    @Published public var items: [DownloadHistoryItem] = []

    private let storageURL: URL

    private init() {
        let baseDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let riprDir = baseDir.appendingPathComponent("ripr", isDirectory: true)
        let legacyDir = baseDir.appendingPathComponent("lennartlol-downloader", isDirectory: true)

        try? FileManager.default.createDirectory(at: riprDir, withIntermediateDirectories: true)
        let riprHistory = riprDir.appendingPathComponent("history.json")
        let legacyHistory = legacyDir.appendingPathComponent("history.json")

        if !FileManager.default.fileExists(atPath: riprHistory.path) && FileManager.default.fileExists(atPath: legacyHistory.path) {
            try? FileManager.default.copyItem(at: legacyHistory, to: riprHistory)
        }

        self.storageURL = riprHistory
        load()
    }

    public func add(item: DownloadHistoryItem) {
        items.removeAll(where: { $0.filePath == item.filePath })
        items.insert(item, at: 0)
        save()
    }

    public func remove(item: DownloadHistoryItem) {
        items.removeAll(where: { $0.id == item.id })
        save()
    }

    public func clearAll() {
        items.removeAll()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Fehler beim Speichern der Historie: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            self.items = try JSONDecoder().decode([DownloadHistoryItem].self, from: data)
        } catch {
            print("Fehler beim Laden der Historie: \(error)")
        }
    }
}
