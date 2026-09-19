import Foundation

public struct ProcessHelper {
    public static var appSupportBinDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return appSupport.appendingPathComponent("ripr/bin")
    }

    public static func findYtDlp() -> (path: String, isPythonModule: Bool) {
        // 1. In Application Support (nach Auto-Update)
        let appSupportYt = appSupportBinDir.appendingPathComponent("yt-dlp").path
        if FileManager.default.isExecutableFile(atPath: appSupportYt) {
            return (appSupportYt, false)
        }

        // 2. Im App-Bundle (Resources/bin/yt-dlp)
        if let bundleBin = Bundle.main.resourceURL?.appendingPathComponent("bin/yt-dlp").path,
           FileManager.default.isExecutableFile(atPath: bundleBin) {
            return (bundleBin, false)
        }

        // 3. Im lokalen Projektordner Binaries (für Entwicklung/Test)
        let localBin = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Binaries/yt-dlp").path
        if FileManager.default.isExecutableFile(atPath: localBin) {
            return (localBin, false)
        }

        // 4. Standalone yt-dlp im System
        let systemCandidates = ["/opt/homebrew/bin/yt-dlp", "/usr/local/bin/yt-dlp"]
        for p in systemCandidates {
            if FileManager.default.isExecutableFile(atPath: p) {
                return (p, false)
            }
        }

        // 5. Fallback auf Python-Modul (-m yt_dlp)
        return (findPython(), true)
    }

    public static func findPython() -> String {
        let candidates = [
            "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3",
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return "/usr/bin/python3"
    }

    public static func makeEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        var searchPaths: [String] = []

        // Priorität 1: Application Support bin
        searchPaths.append(appSupportBinDir.path)

        // Priorität 2: Gebündeltes bin im App Bundle
        if let b = Bundle.main.resourceURL?.appendingPathComponent("bin").path {
            searchPaths.append(b)
        }

        // Priorität 3: Lokales Binaries-Verzeichnis
        searchPaths.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Binaries").path)

        // Priorität 4: Systempfade
        searchPaths.append(contentsOf: [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/Library/Frameworks/Python.framework/Versions/3.12/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ])

        let pathString = searchPaths.joined(separator: ":")
        if let existing = env["PATH"] {
            env["PATH"] = "\(pathString):\(existing)"
        } else {
            env["PATH"] = pathString
        }
        env["PYTHONUNBUFFERED"] = "1"
        return env
    }

    public static func findFFmpeg() -> String? {
        var candidates: [String] = []

        // 1. Application Support
        candidates.append(appSupportBinDir.appendingPathComponent("ffmpeg").path)

        // 2. Im App Bundle
        if let b = Bundle.main.resourceURL?.appendingPathComponent("bin/ffmpeg").path {
            candidates.append(b)
        }

        // 3. Lokales Binaries-Verzeichnis
        candidates.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Binaries/ffmpeg").path)

        // 4. System / Homebrew
        candidates.append(contentsOf: ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg", "/usr/bin/ffmpeg"])

        for c in candidates {
            if FileManager.default.isExecutableFile(atPath: c) {
                return c
            }
        }
        return nil
    }

    public static func findFFprobe() -> String? {
        var candidates: [String] = []

        // 1. Application Support
        candidates.append(appSupportBinDir.appendingPathComponent("ffprobe").path)

        // 2. Im App Bundle
        if let b = Bundle.main.resourceURL?.appendingPathComponent("bin/ffprobe").path {
            candidates.append(b)
        }

        // 3. Lokales Binaries-Verzeichnis
        candidates.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Binaries/ffprobe").path)

        // 4. System / Homebrew
        candidates.append(contentsOf: ["/opt/homebrew/bin/ffprobe", "/usr/local/bin/ffprobe", "/usr/bin/ffprobe"])

        for c in candidates {
            if FileManager.default.isExecutableFile(atPath: c) {
                return c
            }
        }
        return nil
    }

    public static func getVideoDuration(filePath: String) -> Double {
        guard let ffprobePath = findFFprobe() else { return 0.0 }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffprobePath)
        process.arguments = [
            "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            filePath
        ]
        process.environment = makeEnvironment()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let dur = Double(str) {
                return dur
            }
        } catch {}
        return 0.0
    }

    public static func checkFFmpeg() -> (exists: Bool, info: String) {
        guard let path = findFFmpeg() else {
            return (false, "FFmpeg nicht gefunden! Bitte via Homebrew ('brew install ffmpeg') installieren.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-version"]
        process.environment = makeEnvironment()

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), let firstLine = output.components(separatedBy: "\n").first {
                let locationDesc = path.contains(".app/Contents") ? "Gebündelt (Autark)" : path
                return (true, "\(firstLine) [\(locationDesc)]")
            }
            return (true, "FFmpeg gefunden unter \(path)")
        } catch {
            return (true, "FFmpeg vorhanden (\(path))")
        }
    }
}
