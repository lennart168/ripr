import SwiftUI
import AppKit

// MARK: - Native macOS Visual Effect (Liquid Glass / Frosted Glass)
public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material = .sidebar
    public var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(material: NSVisualEffectView.Material = .sidebar, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - AppKit ScrollBar Stripper (hides scrollers while preserving scrolling)
public struct ScrollbarHider: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> ScrollbarHidingNSView {
        ScrollbarHidingNSView()
    }

    public func updateNSView(_ nsView: ScrollbarHidingNSView, context: Context) {
        nsView.stripScrollers()
    }
}

public final class ScrollbarHidingNSView: NSView {
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stripScrollers()
    }

    public override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        stripScrollers()
    }

    public override func layout() {
        super.layout()
        stripScrollers()
    }

    public func stripScrollers() {
        if let enclosing = self.enclosingScrollView {
            Self.disableScrollers(on: enclosing)
        }
        window?.contentView?.hideAllScrollBars()
    }

    public static func disableScrollers(on sv: NSScrollView) {
        if sv.hasVerticalScroller {
            sv.hasVerticalScroller = false
        }
        if sv.hasHorizontalScroller {
            sv.hasHorizontalScroller = false
        }
        sv.verticalScroller?.isHidden = true
        sv.horizontalScroller?.isHidden = true
        sv.verticalScroller?.alphaValue = 0
        sv.horizontalScroller?.alphaValue = 0
        sv.scrollerStyle = .overlay
        sv.autohidesScrollers = true
    }
}

public extension NSView {
    func hideAllScrollBars() {
        if let sv = self as? NSScrollView {
            ScrollbarHidingNSView.disableScrollers(on: sv)
        }
        for subview in subviews {
            subview.hideAllScrollBars()
        }
    }
}

public extension View {
    func removeScrollBars() -> some View {
        self
            .scrollIndicators(.hidden)
            .background(ScrollbarHider())
    }
}

// MARK: - Platform Extensions for Themes & Gradients
extension Platform {
    public var themeColor: Color {
        brandColor
    }

    public var brandColor: Color {
        switch self {
        case .auto: return Color(red: 0.18, green: 0.55, blue: 1.0)
        case .youtube: return Color(red: 1.0, green: 0.0, blue: 0.0) // YouTube Red #FF0000
        case .tiktok: return Color(red: 0.14, green: 0.96, blue: 0.93) // TikTok Cyan #25F4EE
        case .instagram: return Color(red: 0.88, green: 0.19, blue: 0.42) // Instagram Magenta #E1306C
        case .twitter: return Color.primary // X Monochrome
        case .reddit: return Color(red: 1.0, green: 0.27, blue: 0.0) // Reddit Orange #FF4500
        case .twitch: return Color(red: 0.57, green: 0.27, blue: 1.0) // Twitch Violet #9146FF
        case .kick: return Color(red: 0.33, green: 0.99, blue: 0.09) // Kick Neon Green #53FC18
        case .rumble: return Color(red: 0.52, green: 0.78, blue: 0.26) // Rumble Green #85C742
        case .facebook: return Color(red: 0.09, green: 0.47, blue: 0.95) // Facebook Blue #1877F2
        case .pinterest: return Color(red: 0.90, green: 0.0, blue: 0.14) // Pinterest Red #E60023
        case .vimeo: return Color(red: 0.10, green: 0.72, blue: 0.92) // Vimeo Blue #1AB7EA
        case .soundcloud: return Color(red: 1.0, green: 0.33, blue: 0.0) // SoundCloud Sunset Orange #FF5500
        case .daserste: return Color(red: 0.0, green: 0.45, blue: 0.85) // ARD Blue #0073D8
        case .zdf: return Color(red: 0.98, green: 0.49, blue: 0.10) // ZDF Orange #FA7D19
        case .universal: return Color(red: 0.25, green: 0.55, blue: 1.0) // Safari Blue
        }
    }

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [brandColor, brandColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public var buttonTextColor: Color {
        switch self {
        case .tiktok, .kick:
            return .black
        default:
            return .white
        }
    }
}

// MARK: - Liquid Glass Button Styles
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat

    public init(cornerRadius: CGFloat = 10, horizontalPadding: CGFloat = 14, verticalPadding: CGFloat = 7) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(configuration.isPressed ? 0.2 : 0.38), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.04 : 0.12), radius: 6, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public struct ProminentGlassButtonStyle: ButtonStyle {
    public var gradient: LinearGradient
    public var shadowColor: Color
    public var textColor: Color
    public var cornerRadius: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat

    public init(
        gradient: LinearGradient = LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
        shadowColor: Color = Color.accentColor,
        textColor: Color = .white,
        cornerRadius: CGFloat = 12,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 8
    ) {
        self.gradient = gradient
        self.shadowColor = shadowColor
        self.textColor = textColor
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(gradient)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial.opacity(0.2))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(configuration.isPressed ? 0.25 : 0.55), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: shadowColor.opacity(configuration.isPressed ? 0.2 : 0.4), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shared Tab Router
public final class TabRouter: ObservableObject {
    public static let shared = TabRouter()

    @Published public var selectedTab: String = "Download"

    public func navigateToDownload() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            selectedTab = "Download"
        }
    }
}

// MARK: - Standard Tab Hero Header
public struct TabHeroHeader: View {
    public let icon: String
    public let color: Color
    public let title: String
    public let subtitle: String

    public var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 72, height: 72)
                    .blur(radius: 8)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 22, weight: .bold))

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 540)
        }
    }
}

// MARK: - Asset & Real Icon Loader
public struct BrandIconView: View {
    public let platform: Platform?
    public let customName: String?
    public let fallbackSymbol: String
    public let size: CGFloat
    public let color: Color?

    public init(platform: Platform? = nil, customName: String? = nil, fallbackSymbol: String = "sparkles", size: CGFloat = 20, color: Color? = .accentColor) {
        self.platform = platform
        self.customName = customName
        self.fallbackSymbol = fallbackSymbol
        self.size = size
        self.color = color
    }

    private var loadedImage: NSImage? {
        var candidateNames: [String] = []
        if let customName = customName {
            candidateNames.append(customName)
            if customName == "rlogo" || customName == "logo" || customName == "app_logo" {
                candidateNames.append(contentsOf: ["rlogo", "r_logo", "r logo", "logo"])
            }
        }
        if let p = platform {
            switch p {
            case .youtube:
                candidateNames.append(contentsOf: ["youtube", "YouTube"])
            case .tiktok:
                candidateNames.append(contentsOf: ["tiktok", "TikTok"])
            case .instagram:
                candidateNames.append(contentsOf: ["instagram", "Instagram"])
            case .twitter:
                candidateNames.append(contentsOf: ["x", "twitter", "Twitter", "X"])
            case .reddit:
                candidateNames.append(contentsOf: ["reddit", "Reddit"])
            case .twitch:
                candidateNames.append(contentsOf: ["twitch", "Twitch"])
            case .kick:
                candidateNames.append(contentsOf: ["kick", "Kick"])
            case .rumble:
                candidateNames.append(contentsOf: ["rumble", "Rumble"])
            case .facebook:
                candidateNames.append(contentsOf: ["facebook", "Facebook", "fb"])
            case .pinterest:
                candidateNames.append(contentsOf: ["pinterest", "Pinterest"])
            case .vimeo:
                candidateNames.append(contentsOf: ["vimeo", "Vimeo"])
            case .soundcloud:
                candidateNames.append(contentsOf: ["soundcloud", "SoundCloud"])
            case .daserste:
                candidateNames.append(contentsOf: ["daserste", "ard", "ARD"])
            case .zdf:
                candidateNames.append(contentsOf: ["zdf", "ZDF"])
            case .universal:
                candidateNames.append(contentsOf: ["universal", "globe", "web"])
            case .auto:
                candidateNames.append(contentsOf: ["rlogo", "logo", "sparkles"])
            }
        }
        if candidateNames.isEmpty {
            candidateNames = ["rlogo", "logo", "sparkles"]
        }

        for name in candidateNames {
            for ext in ["png", "svg", "pdf", "jpg", "jpeg", "webp"] {
                // 1. App Bundle Resources
                if let url = Bundle.main.url(forResource: name, withExtension: ext),
                   let img = NSImage(contentsOf: url) {
                    return img
                }
                // 2. Local Icons directory in project folder or adjacent
                let localPaths = [
                    URL(fileURLWithPath: "Icons/\(name).\(ext)"),
                    Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("Icons/\(name).\(ext)")
                ]
                for p in localPaths {
                    if FileManager.default.fileExists(atPath: p.path), let img = NSImage(contentsOf: p) {
                        return img
                    }
                }
            }
        }
        return nil
    }

    public var body: some View {
        let tint = color ?? platform?.brandColor ?? .accentColor
        if let img = loadedImage {
            Image(nsImage: img)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(tint)
        } else {
            Image(systemName: platform?.iconName ?? fallbackSymbol)
                .font(.system(size: size * 0.85, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: size, height: size)
        }
    }
}

public struct PlatformBadge: View {
    public let name: String
    public let icon: String
    public var color: Color? = nil
    public var platform: Platform? = nil

    public init(name: String, icon: String, color: Color? = nil, platform: Platform? = nil) {
        self.name = name
        self.icon = icon
        self.color = color
        self.platform = platform
    }

    public var body: some View {
        let badgeColor = color ?? platform?.brandColor ?? .accentColor
        HStack(spacing: 7) {
            BrandIconView(platform: platform, customName: name.lowercased(), fallbackSymbol: icon, size: 14, color: badgeColor)
            Text(name)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(.primary.opacity(0.88))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.6))
        .shadow(color: badgeColor.opacity(0.18), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Animated Infinite Platform Marquee Carousel Banner
public struct PlatformMarqueeBanner: View {
    let platforms: [Platform] = [
        .youtube, .tiktok, .instagram, .twitter, .reddit,
        .twitch, .kick, .rumble, .facebook, .soundcloud,
        .pinterest, .vimeo, .daserste, .zdf, .universal
    ]

    private let speed: Double = 24.0
    private let spacing: CGFloat = 34

    public var body: some View {
        TimelineView(.animation) { timeline in
            MarqueeContent(
                platforms: platforms,
                date: timeline.date,
                speed: speed,
                spacing: spacing
            )
        }
        .frame(width: 400, height: 52)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.1), location: 0.06),
                    .init(color: .black, location: 0.25),
                    .init(color: .black, location: 0.75),
                    .init(color: .black.opacity(0.1), location: 0.94),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

private struct MarqueeContent: View {
    let platforms: [Platform]
    let date: Date
    let speed: Double
    let spacing: CGFloat

    @State private var rowWidth: CGFloat = 0

    var body: some View {
        GeometryReader { _ in
            let effectiveWidth = rowWidth > 0 ? rowWidth : 1200
            // Bewege langsam von links nach rechts
            let currentOffset = CGFloat(date.timeIntervalSinceReferenceDate * speed)
                .truncatingRemainder(dividingBy: effectiveWidth)

            HStack(spacing: spacing) {
                badgeGroup
                    .background(
                        GeometryReader { rowProxy in
                            Color.clear.preference(key: MarqueeWidthPreferenceKey.self, value: rowProxy.size.width + spacing)
                        }
                    )
                badgeGroup
                badgeGroup
            }
            .offset(x: currentOffset - effectiveWidth)
        }
        .onPreferenceChange(MarqueeWidthPreferenceKey.self) { newWidth in
            if newWidth > 0 && self.rowWidth != newWidth {
                self.rowWidth = newWidth
            }
        }
    }

    @ViewBuilder
    private var badgeGroup: some View {
        HStack(spacing: spacing) {
            ForEach(platforms) { platform in
                BrandIconView(
                    platform: platform,
                    customName: nil,
                    fallbackSymbol: platform.iconName,
                    size: 36,
                    color: platform.brandColor
                )
                .shadow(color: platform.brandColor.opacity(0.35), radius: 8, x: 0, y: 3)
            }
        }
    }
}

private struct MarqueeWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Master Video & Download Experience Card
public struct MasterVideoCard: View {
    public let metadata: VideoMetadata
    public let platform: Platform
    @ObservedObject public var engine: EngineService
    @Binding public var isAudioMode: Bool
    @Binding public var selectedFormat: FormatOption?
    @Binding public var selectedFolder: URL
    @Binding public var convertToH265: Bool
    public let onFormatModeChanged: () -> Void
    public let onChooseFolder: () -> Void
    public let onStartDownload: () -> Void
    public let onReset: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            mediaHeader

            Divider().opacity(0.2)

            if engine.isConverting || engine.isDownloading || engine.isAnalyzing {
                downloadingProgressView
            } else if engine.finishedFilePath != nil {
                successView
            } else {
                idleConfigView
            }
        }
        .padding(18)
        .frame(maxWidth: 680)
        .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 5)
    }

    // 1. Media Preview Header
    @ViewBuilder
    private var mediaHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 160, height: 102)

                if let url = metadata.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 102).clipped().cornerRadius(12)
                        default:
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }

                if !metadata.durationFormatted.isEmpty && metadata.durationFormatted != "0:00" && metadata.durationFormatted != "Unbekannt" {
                    Text(metadata.durationFormatted)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .padding(5)
                }
            }
            .frame(width: 160, height: 102)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(metadata.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Info Zeile: Kanal, Views, Dateigröße
                HStack(spacing: 10) {
                    if !metadata.uploader.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 11))
                            Text(metadata.uploader)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let views = metadata.viewCountFormatted {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 10))
                            Text(views)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }

                    if let sizeStr = selectedFormat?.estimatedSizeFormatted ?? metadata.estimatedFileSizeFormatted {
                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive")
                                .font(.system(size: 10))
                            Text(sizeStr)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }

                    if metadata.isLive {
                        HStack(spacing: 5) {
                            Circle().fill(Color.red).frame(width: 7, height: 7)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red.opacity(0.9)))
                    }
                }

                // Format- & Qualitätsauswahl direkt neben dem Thumbnail, bis ganz nach rechts durchgehend!
                HStack(spacing: 8) {
                    // Dropdown 1: Format-Typ (Video / Audio)
                    Menu {
                        Button(action: {
                            if isAudioMode {
                                isAudioMode = false
                                onFormatModeChanged()
                            }
                        }) {
                            if !isAudioMode {
                                Label("Video (MP4)", systemImage: "checkmark")
                            } else {
                                Label("Video (MP4)", systemImage: "film")
                            }
                        }

                        Button(action: {
                            if !isAudioMode {
                                isAudioMode = true
                                onFormatModeChanged()
                            }
                        }) {
                            if isAudioMode {
                                Label("Audio (MP3)", systemImage: "checkmark")
                            } else {
                                Label("Audio (MP3)", systemImage: "waveform")
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isAudioMode ? "waveform" : "film")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.accentColor)

                            Text(isAudioMode ? "Audio (MP3)" : "Video (MP4)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .frame(width: 140, height: 36)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.1), lineWidth: 0.6))
                        .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(engine.isDownloading || engine.isConverting || engine.isAnalyzing)

                    // Dropdown 2: Qualität / Format (geht komplett bis nach rechts durch!)
                    Menu {
                        ForEach(isAudioMode ? metadata.audioOptions : metadata.videoOptions) { opt in
                            Button(action: { selectedFormat = opt }) {
                                if selectedFormat?.id == opt.id {
                                    Label(opt.display, systemImage: "checkmark")
                                } else {
                                    Text(opt.display)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isAudioMode ? "waveform.badge.magnifyingglass" : "sparkles.tv")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))

                            Text(selectedFormat?.display ?? (isAudioMode ? metadata.audioOptions.first?.display : metadata.videoOptions.first?.display) ?? "Beste Qualität")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.1), lineWidth: 0.6))
                        .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .disabled(engine.isDownloading || engine.isConverting || engine.isAnalyzing)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // 2. Success View
    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .bold))

                Text("Download erfolgreich abgeschlossen!")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()
            }

            if let path = engine.finishedFilePath {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Text(URL(fileURLWithPath: path).lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
            }

            HStack(spacing: 12) {
                Button(action: { engine.revealInFinder() }) {
                    Label("Im Finder anzeigen", systemImage: "folder.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 12))

                Button(action: { engine.openFile() }) {
                    Label("Jetzt abspielen", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ProminentGlassButtonStyle(gradient: platform.gradient, shadowColor: platform.themeColor, cornerRadius: 12))
            }

            if !isAudioMode && !engine.isConverting && !engine.statusText.contains("H.265") && !(engine.finishedFilePath?.contains("[H265]") ?? false) {
                Button(action: { engine.convertCurrentFileToH265() }) {
                    Label("Nachträglich in H.265 (HEVC) umwandeln", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 12))
            }

            Button(action: onReset) {
                Label("Weiteren Download starten", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 10))
            .padding(.top, 4)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 0.8))
    }

    // 3. Downloading Progress View
    @ViewBuilder
    private var downloadingProgressView: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: engine.isConverting ? "bolt.fill" : (engine.isLive ? "record.circle.fill" : "arrow.down.circle.fill"))
                        .foregroundColor(engine.isConverting ? .accentColor : (engine.isLive ? .red : platform.themeColor))
                        .font(.system(size: 17, weight: .bold))

                    Text(engine.statusText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: { engine.cancel() }) {
                    Label(engine.isLive ? "Aufnahme beenden" : "Abbrechen", systemImage: engine.isLive ? "stop.fill" : "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.red.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }

            if engine.isAnalyzing || (engine.isLive && engine.isDownloading) {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(platform.themeColor)
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)

                        Capsule()
                            .fill(platform.gradient)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(engine.percent / 100.0))), height: 8)
                            .animation(.linear(duration: 0.2), value: engine.percent)
                    }
                }
                .frame(height: 8)
            }

            HStack(spacing: 10) {
                if !engine.isLive && (engine.isDownloading || engine.isConverting) {
                    Text(String(format: "%.1f %%", engine.percent))
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.primary)
                }

                if !engine.detailsText.isEmpty {
                    Text(engine.detailsText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !engine.etaText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(engine.etaText)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
    }

    // 4. Idle / Configuration View
    @ViewBuilder
    private var idleConfigView: some View {
        VStack(spacing: 10) {
            // Speichern in:
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 13))

                Text("Speichern in:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text(selectedFolder.lastPathComponent)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)

                Text("(\(selectedFolder.path))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: onChooseFolder) {
                    Text("Ändern")
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.6))

            // H.265 Checkbox im gleichen Design
            if !isAudioMode {
                HStack(spacing: 10) {
                    Image(systemName: "film.stack")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 13))

                    Text("Automatisch in H.265 (HEVC) umwandeln")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Text("• Apple Silicon Hardwarebeschleunigung")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))

                    Spacer()

                    Toggle("", isOn: $convertToH265)
                        .toggleStyle(.checkbox)
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.6))
                .contentShape(Rectangle())
                .onTapGesture {
                    convertToH265.toggle()
                }
            }

            if let err = engine.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 13))

                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.12)))
            }

            Button(action: onStartDownload) {
                HStack(spacing: 8) {
                    Image(systemName: metadata.isLive ? "record.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(metadata.isLive ? "Live-Aufnahme starten" : "Jetzt herunterladen")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                ProminentGlassButtonStyle(
                    gradient: metadata.isLive ? LinearGradient(colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) : platform.gradient,
                    shadowColor: metadata.isLive ? Color.red : platform.themeColor,
                    cornerRadius: 14
                )
            )
            .padding(.top, 4)
        }
    }
}

// MARK: - Master Playlist Card (Liquid Glass)
public struct MasterPlaylistCard: View {
    public let playlist: PlaylistMetadata
    public let platform: Platform
    @ObservedObject public var engine: EngineService
    @Binding public var isAudioMode: Bool
    @Binding public var selectedFormat: FormatOption?
    @Binding public var selectedFolder: URL
    @Binding public var selectedItemIds: Set<String>
    @Binding public var createSubfolder: Bool
    @Binding public var numberFiles: Bool
    public let onFormatModeChanged: () -> Void
    public let onChooseFolder: () -> Void
    public let onStartDownload: () -> Void
    public let onReset: () -> Void
    public let onSelectAll: () -> Void
    public let onDeselectAll: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            playlistHeader

            Divider().opacity(0.2)

            if engine.isDownloading {
                downloadingProgressView
            } else if engine.finishedFilePath != nil {
                successView
            } else {
                idleConfigView
            }
        }
        .padding(18)
        .frame(maxWidth: 680)
        .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 5)
    }

    // 1. Playlist Header
    @ViewBuilder
    private var playlistHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 140, height: 95)

                if let url = playlist.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 95).clipped().cornerRadius(12)
                        default:
                            Image(systemName: "play.square.stack.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                } else {
                    Image(systemName: "play.square.stack.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Elementanzahl-Badge auf dem Thumbnail
                HStack(spacing: 3) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(playlist.itemCount)")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.75))
                .cornerRadius(6)
                .padding(6)
            }
            .frame(width: 140, height: 95)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("PLAYLIST")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)))

                    if !playlist.totalDurationFormatted.isEmpty {
                        Text(playlist.totalDurationFormatted)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: onReset) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                Text(playlist.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(playlist.uploader)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    // 2. Download Progress
    @ViewBuilder
    private var downloadingProgressView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(engine.statusText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "%.1f%%", engine.percent))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
            }

            ProgressView(value: engine.percent, total: 100.0)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(.purple)

            HStack {
                if !engine.detailsText.isEmpty {
                    Text(engine.detailsText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if !engine.etaText.isEmpty {
                    Text(engine.etaText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                Button(role: .destructive, action: { engine.cancel() }) {
                    Label("Abbrechen", systemImage: "xmark")
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8, horizontalPadding: 12, verticalPadding: 6))
            }
        }
        .padding(.top, 4)
    }

    // 3. Success View
    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Playlist-Download abgeschlossen!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Alle ausgewählten Dateien wurden gesichert.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                if let path = engine.finishedFilePath {
                    Button(action: {
                        NotificationService.shared.showInFinder(atPath: path)
                    }) {
                        Label("Im Finder anzeigen", systemImage: "folder")
                    }
                    .buttonStyle(ProminentGlassButtonStyle(
                        gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        cornerRadius: 10,
                        horizontalPadding: 14,
                        verticalPadding: 8
                    ))
                }

                Button(action: onReset) {
                    Label("Neue Playlist laden", systemImage: "arrow.clockwise")
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 10, horizontalPadding: 14, verticalPadding: 8))

                Spacer()
            }
        }
        .padding(.top, 4)
    }

    // 4. Idle Config View
    @ViewBuilder
    private var idleConfigView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Video / Audio Toggle & Format Dropdown
            HStack(spacing: 10) {
                // Mode Switcher
                HStack(spacing: 2) {
                    Button(action: {
                        isAudioMode = false
                        onFormatModeChanged()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "film")
                            Text("Video")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(!isAudioMode ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(!isAudioMode ? RoundedRectangle(cornerRadius: 7).fill(Color.accentColor) : nil)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        isAudioMode = true
                        onFormatModeChanged()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                            Text("Audio")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isAudioMode ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isAudioMode ? RoundedRectangle(cornerRadius: 7).fill(Color.purple) : nil)
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(0.06)))

                // Format Dropdown
                Menu {
                    let options = isAudioMode ? PlaylistFormatPresets.audioOptions : PlaylistFormatPresets.videoOptions
                    ForEach(options) { opt in
                        Button(action: { selectedFormat = opt }) {
                            if selectedFormat?.display == opt.display {
                                Label(opt.display, systemImage: "checkmark")
                            } else {
                                Text(opt.display)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: isAudioMode ? "music.note" : "sparkles.tv")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(selectedFormat?.display ?? (isAudioMode ? "MP3 (320 kbps)" : "Beste Qualität"))
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
                }
                .menuStyle(.borderlessButton)
            }

            // Options: Unterordner & Nummerierung
            HStack(spacing: 16) {
                Toggle(isOn: $createSubfolder) {
                    Text("In eigenem Unterordner speichern")
                        .font(.system(size: 11, weight: .medium))
                }
                .toggleStyle(.checkbox)

                Toggle(isOn: $numberFiles) {
                    Text("Dateien durchnummerieren (01, 02...)")
                        .font(.system(size: 11, weight: .medium))
                }
                .toggleStyle(.checkbox)
            }

            // Speicherort
            HStack {
                Label(selectedFolder.path, systemImage: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(action: onChooseFolder) {
                    Text("Ändern...")
                        .font(.system(size: 11))
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 6, horizontalPadding: 8, verticalPadding: 4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))

            // Playlist Items Header mit Auswahlschaltern
            HStack {
                Text("Playlist-Elemente:")
                    .font(.system(size: 12, weight: .bold))

                Spacer()

                Text("\(selectedItemIds.count) von \(playlist.items.count) ausgewählt")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Button(action: onSelectAll) {
                    Text("Alle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 6, horizontalPadding: 7, verticalPadding: 3))

                Button(action: onDeselectAll) {
                    Text("Keine")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 6, horizontalPadding: 7, verticalPadding: 3))
            }

            // Playlist Items Scroll-Liste
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(playlist.items) { item in
                        let isSelected = selectedItemIds.contains(item.id)
                        HStack(spacing: 8) {
                            Button(action: {
                                if isSelected {
                                    selectedItemIds.remove(item.id)
                                } else {
                                    selectedItemIds.insert(item.id)
                                }
                            }) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(isSelected ? .purple : .secondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)

                            Text(String(format: "%02d", item.index))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 20)

                            if let thumb = item.thumbnailURL {
                                AsyncImage(url: thumb) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().aspectRatio(contentMode: .fill)
                                            .frame(width: 38, height: 24).clipped().cornerRadius(4)
                                    default:
                                        RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.2))
                                            .frame(width: 38, height: 24)
                                    }
                                }
                            }

                            Text(item.title)
                                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? .primary : .secondary)
                                .lineLimit(1)

                            Spacer()

                            if !item.durationFormatted.isEmpty {
                                Text(item.durationFormatted)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? Color.purple.opacity(0.08) : Color.clear)
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .background(ScrollbarHider())
            }
            .frame(maxHeight: 180)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.06), lineWidth: 1))
            .removeScrollBars()

            // Fehlermeldung falls vorhanden
            if let err = engine.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.12)))
            }

            // Big Download Button
            Button(action: onStartDownload) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(selectedItemIds.isEmpty ? "Keine Elemente ausgewählt" : "Playlist herunterladen (\(selectedItemIds.count) \(isAudioMode ? "Tracks" : "Videos"))")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(
                ProminentGlassButtonStyle(
                    gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                    shadowColor: .purple,
                    cornerRadius: 14
                )
            )
            .disabled(selectedItemIds.isEmpty)
            .opacity(selectedItemIds.isEmpty ? 0.6 : 1.0)
            .padding(.top, 4)
        }
    }
}

// MARK: - Unified Auto Downloader View (Liquid Glass Design)
public struct AutoDownloaderView: View {
    @StateObject private var engine = EngineService()
    @ObservedObject private var settings = SettingsManager.shared

    @State private var urlString: String = ""
    @State private var detectedPlatform: Platform = .auto
    @State private var metadata: VideoMetadata? = nil
    @State private var playlistMetadata: PlaylistMetadata? = nil
    @State private var showPlaylistMode: Bool = false
    @State private var selectedPlaylistItemIds: Set<String> = []
    @State private var createSubfolder: Bool = true
    @State private var numberFiles: Bool = true
    @State private var isAudioMode: Bool = false
    @State private var selectedFormat: FormatOption? = nil
    @State private var selectedFolder: URL = SettingsManager.shared.downloadFolder
    @State private var convertToH265: Bool = SettingsManager.shared.convertToH265

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 16)
                heroSection
                inputCard
                if metadata == nil && playlistMetadata == nil && !engine.isAnalyzing {
                    platformBadgesRow
                }
                if metadata != nil && playlistMetadata != nil {
                    comboLinkSwitcher
                }
                if showPlaylistMode, let playlist = playlistMetadata {
                    playlistCard(playlist: playlist)
                } else if let meta = metadata {
                    mediaCard(meta: meta)
                } else if let playlist = playlistMetadata {
                    playlistCard(playlist: playlist)
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .background(ScrollbarHider())
        }
        .removeScrollBars()
        .onAppear {
            self.selectedFolder = settings.downloadFolder
            self.convertToH265 = settings.convertToH265
        }
    }

    private var analyzeButtonGradient: LinearGradient {
        if detectedPlatform != .auto {
            return detectedPlatform.gradient
        }
        return LinearGradient(
            colors: [Color(red: 0.18, green: 0.55, blue: 1.0), Color(red: 0.22, green: 0.40, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var analyzeButtonShadowColor: Color {
        if detectedPlatform != .auto {
            return detectedPlatform.brandColor
        }
        return Color.accentColor
    }

    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                BrandIconView(
                    platform: nil,
                    customName: "rlogo",
                    fallbackSymbol: "sparkles",
                    size: 34,
                    color: .white
                )
                .shadow(
                    color: Color.accentColor.opacity(0.45),
                    radius: 10,
                    x: 0,
                    y: 3
                )

                Text("ripr")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            Text("Füge einen beliebigen Link von YouTube, TikTok, Instagram, Twitch oder dem Web ein.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 540)
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var inputCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                BrandIconView(
                    platform: detectedPlatform != .auto ? detectedPlatform : nil,
                    customName: nil,
                    fallbackSymbol: "link",
                    size: 20,
                    color: detectedPlatform != .auto ? detectedPlatform.brandColor : .secondary
                )
                .shadow(
                    color: detectedPlatform != .auto ? detectedPlatform.brandColor.opacity(0.35) : Color.clear,
                    radius: 6,
                    x: 0,
                    y: 2
                )
                .frame(width: 26, height: 26)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: detectedPlatform)

                TextField("Link einfügen (YouTube, TikTok etc.)", text: $urlString)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .regular))
                    .onSubmit { handleAnalyzeTap() }
                    .onChange(of: urlString) { oldUrl, newUrl in
                        let trimmed = newUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            let plat = Platform.detect(from: trimmed)
                            self.detectedPlatform = plat

                            // Automatisch analysieren wenn ein kompletter Link eingefügt wurde
                            let insertedCount = newUrl.count - oldUrl.count
                            let isLikelyURL = trimmed.hasPrefix("http://") ||
                                              trimmed.hasPrefix("https://") ||
                                              trimmed.hasPrefix("www.") ||
                                              plat != .auto ||
                                              trimmed.contains(".com") ||
                                              trimmed.contains(".be") ||
                                              trimmed.contains(".tv") ||
                                              trimmed.contains(".net")

                            if isLikelyURL && (insertedCount > 3 || oldUrl.isEmpty) && trimmed.count >= 8 && !engine.isAnalyzing {
                                startInspect()
                            }
                        } else {
                            detectedPlatform = .auto
                        }
                    }

                if !urlString.isEmpty {
                    Button(action: {
                        urlString = ""
                        detectedPlatform = .auto
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: handleAnalyzeTap) {
                    HStack(spacing: 7) {
                        if engine.isAnalyzing {
                            ProgressView().scaleEffect(0.65).frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text("Analysieren")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .buttonStyle(ProminentGlassButtonStyle(
                    gradient: analyzeButtonGradient,
                    shadowColor: analyzeButtonShadowColor,
                    textColor: detectedPlatform != .auto ? detectedPlatform.buttonTextColor : .white,
                    cornerRadius: 12,
                    horizontalPadding: 20,
                    verticalPadding: 10
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: detectedPlatform)
                .disabled(engine.isAnalyzing)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: 680)
            .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 5)

            if engine.isAnalyzing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Video-Informationen & Qualitäten werden geladen...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 2)
            } else if let err = engine.errorMessage, metadata == nil {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.25), lineWidth: 0.6))
            }
        }
    }

    @ViewBuilder
    private var platformBadgesRow: some View {
        VStack(spacing: 20) {
            Text("Unterstützte Plattformen:")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.85))
                .textCase(.uppercase)
                .tracking(0.8)

            PlatformMarqueeBanner()
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private var comboLinkSwitcher: some View {
        HStack(spacing: 12) {
            Button(action: {
                showPlaylistMode = false
                updateDefaultFormat()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "film.fill")
                    Text("Nur dieses Video laden")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(!showPlaylistMode ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(!showPlaylistMode ? Color.accentColor : Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                showPlaylistMode = true
                updateDefaultPlaylistFormat()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.square.stack.fill")
                    Text("Ganze Playlist laden (\(playlistMetadata?.items.count ?? 0) Elemente)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(showPlaylistMode ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(showPlaylistMode ? Color.purple : Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func mediaCard(meta: VideoMetadata) -> some View {
        MasterVideoCard(
            metadata: meta,
            platform: detectedPlatform != .auto ? detectedPlatform : .universal,
            engine: engine,
            isAudioMode: $isAudioMode,
            selectedFormat: $selectedFormat,
            selectedFolder: $selectedFolder,
            convertToH265: $convertToH265,
            onFormatModeChanged: { updateDefaultFormat() },
            onChooseFolder: { chooseFolder() },
            onStartDownload: { startDownload() },
            onReset: { reset() }
        )
        .transition(.asymmetric(insertion: .scale(scale: 0.97).combined(with: .opacity), removal: .opacity))
    }

    @ViewBuilder
    private func playlistCard(playlist: PlaylistMetadata) -> some View {
        MasterPlaylistCard(
            playlist: playlist,
            platform: detectedPlatform != .auto ? detectedPlatform : .universal,
            engine: engine,
            isAudioMode: $isAudioMode,
            selectedFormat: $selectedFormat,
            selectedFolder: $selectedFolder,
            selectedItemIds: $selectedPlaylistItemIds,
            createSubfolder: $createSubfolder,
            numberFiles: $numberFiles,
            onFormatModeChanged: { updateDefaultPlaylistFormat() },
            onChooseFolder: { chooseFolder() },
            onStartDownload: { startPlaylistDownload() },
            onReset: { reset() },
            onSelectAll: { selectedPlaylistItemIds = Set(playlist.items.map { $0.id }) },
            onDeselectAll: { selectedPlaylistItemIds = [] }
        )
        .transition(.asymmetric(insertion: .scale(scale: 0.97).combined(with: .opacity), removal: .opacity))
    }

    private func reset() {
        self.metadata = nil
        self.playlistMetadata = nil
        self.showPlaylistMode = false
        self.selectedPlaylistItemIds = []
        self.selectedFormat = nil
        self.urlString = ""
        self.detectedPlatform = .auto
        self.engine.reset()
    }

    private func handleAnalyzeTap() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            pasteAndInspect()
        } else {
            startInspect()
        }
    }

    private func pasteAndInspect() {
        if let str = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty {
            self.urlString = str
            self.detectedPlatform = Platform.detect(from: str)
            startInspect()
        } else {
            self.engine.errorMessage = "Kein Link in der Zwischenablage gefunden."
        }
    }

    private func startInspect() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        metadata = nil
        playlistMetadata = nil
        showPlaylistMode = false
        selectedPlaylistItemIds = []
        selectedFormat = nil
        let targetPlat = Platform.detect(from: trimmed)
        self.detectedPlatform = targetPlat
        engine.startAnalyzing()

        Task {
            do {
                let result = try await InspectorService.inspect(url: trimmed, platform: targetPlat)
                await MainActor.run {
                    switch result {
                    case .video(let video, let associatedPlaylist):
                        self.metadata = video
                        self.playlistMetadata = associatedPlaylist
                        self.showPlaylistMode = false
                        if let playlist = associatedPlaylist {
                            self.selectedPlaylistItemIds = Set(playlist.items.map { $0.id })
                        }
                        self.updateDefaultFormat()
                    case .playlist(let playlist):
                        self.playlistMetadata = playlist
                        self.metadata = nil
                        self.showPlaylistMode = true
                        self.selectedPlaylistItemIds = Set(playlist.items.map { $0.id })
                        self.updateDefaultPlaylistFormat()
                    }
                    self.engine.finishAnalyzing()
                }
            } catch {
                await MainActor.run {
                    self.engine.finishAnalyzing()
                    self.engine.errorMessage = "Analyse fehlgeschlagen: \(error.localizedDescription)"
                }
            }
        }
    }

    private func updateDefaultFormat() {
        guard let meta = metadata else { return }
        if isAudioMode {
            selectedFormat = meta.audioOptions.first
        } else {
            selectedFormat = meta.videoOptions.first
        }
    }

    private func updateDefaultPlaylistFormat() {
        if isAudioMode {
            selectedFormat = PlaylistFormatPresets.audioOptions.first
        } else {
            selectedFormat = PlaylistFormatPresets.videoOptions.first
        }
    }

    private func startDownload() {
        guard let meta = metadata, let format = selectedFormat else { return }
        engine.startDownload(
            url: urlString.trimmingCharacters(in: .whitespacesAndNewlines),
            format: format,
            outputFolder: selectedFolder,
            platform: detectedPlatform != .auto ? detectedPlatform : .universal,
            isLive: meta.isLive,
            convertToH265: convertToH265,
            title: meta.title,
            uploader: meta.uploader,
            thumbnailURL: meta.thumbnailURL?.absoluteString
        )
    }

    private func startPlaylistDownload() {
        guard let playlist = playlistMetadata, let format = selectedFormat else { return }
        let selectedIndices = playlist.items
            .filter { selectedPlaylistItemIds.contains($0.id) }
            .map { $0.index }

        engine.startPlaylistDownload(
            playlist: playlist,
            selectedIndices: selectedIndices,
            format: format,
            outputFolder: selectedFolder,
            platform: detectedPlatform != .auto ? detectedPlatform : .universal,
            createSubfolder: createSubfolder,
            numberFiles: numberFiles
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = selectedFolder
        if panel.runModal() == .OK, let url = panel.url {
            selectedFolder = url
            settings.downloadFolder = url
        }
    }
}

// MARK: - Download History View (Liquid Glass)
public struct HistoryView: View {
    @ObservedObject private var history = HistoryManager.shared

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Hero Header
                TabHeroHeader(
                    icon: "clock.arrow.circlepath",
                    color: .accentColor,
                    title: "Download-Historie",
                    subtitle: "Alle deine heruntergeladenen Videos und Audiospuren übersichtlich an einem Ort."
                )

                if !history.items.isEmpty {
                    HStack {
                        Spacer()
                        Button(role: .destructive, action: { history.clearAll() }) {
                            Label("Historie leeren", systemImage: "trash")
                        }
                        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                    }
                    .frame(maxWidth: 660)
                }

                if history.items.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Keine Downloads in der Historie")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("Erfolgreich heruntergeladene Videos und Audiospuren erscheinen hier automatisch.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .padding(36)
                    .frame(maxWidth: 660)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 5)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(history.items) { item in
                            HistoryItemCard(item: item, onDelete: { history.remove(item: item) })
                        }
                    }
                    .frame(maxWidth: 660)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .background(ScrollbarHider())
        }
        .removeScrollBars()
    }
}

public struct HistoryItemCard: View {
    public let item: DownloadHistoryItem
    public let onDelete: () -> Void

    public var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 84, height: 52)

                if let thumbStr = item.thumbnailURL, let url = URL(string: thumbStr) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 84, height: 52).clipped().cornerRadius(8)
                        } else {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "film.fill")
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 84, height: 52)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.5))

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if !item.platform.isEmpty {
                        Text(item.platform)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
                            .foregroundColor(.accentColor)
                    }

                    if !item.uploader.isEmpty {
                        Text(item.uploader)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Text("•").foregroundColor(.secondary)
                    }

                    Text(item.formatDisplay)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Text("•").foregroundColor(.secondary)

                    Text(item.formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: {
                    NSWorkspace.shared.selectFile(item.filePath, inFileViewerRootedAtPath: "")
                }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                .help("Im Finder anzeigen")

                if item.fileExists {
                    Button(action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: item.filePath))
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(ProminentGlassButtonStyle(cornerRadius: 8))
                    .help("Datei abspielen")
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Aus Historie entfernen")
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(.regularMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 0.6))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Settings View (Liquid Glass Design)
public struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var updater = UpdaterService.shared
    @ObservedObject private var appUpdater = AppUpdaterService.shared
    @ObservedObject private var notifications = NotificationService.shared

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Hero Header
                TabHeroHeader(
                    icon: "gearshape.fill",
                    color: .accentColor,
                    title: "Einstellungen",
                    subtitle: "Verwalte Standard-Speicherort, App- & Engine-Updates sowie Login-Cookies."
                )

                VStack(alignment: .leading, spacing: 18) {
                    // Speicherort Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Standard-Speicherort", systemImage: "folder.fill")
                            .font(.system(size: 14, weight: .bold))

                        HStack {
                            Text(settings.downloadFolder.path)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

                            Button(action: chooseFolder) {
                                Label("Ändern...", systemImage: "pencil")
                            }
                            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // ripr App-Updates Card (GitHub Releases)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("ripr App-Aktualisierung (GitHub)", systemImage: "arrow.down.app.fill")
                                .font(.system(size: 14, weight: .bold))

                            Spacer()

                            if let latest = appUpdater.latestVersion, latest != appUpdater.currentVersion {
                                Text("v\(latest) verfügbar")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.orange))
                            }
                        }

                        HStack {
                            Text("Installierte Version: **v\(appUpdater.currentVersion)**")
                                .font(.system(size: 13))

                            Spacer()

                            Button(action: { appUpdater.checkForUpdates() }) {
                                if case .checking = appUpdater.state {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Label("Nach Updates suchen", systemImage: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                            .disabled(appUpdater.state == .checking || appUpdater.state.isDownloadingOrExtracting)

                            switch appUpdater.state {
                            case .available(let version, _, _):
                                Button(action: { appUpdater.startDownload() }) {
                                    Label("Auf v\(version) aktualisieren", systemImage: "arrow.up.circle.fill")
                                }
                                .buttonStyle(ProminentGlassButtonStyle(cornerRadius: 8))

                            case .readyToInstall(let version):
                                Button(action: { appUpdater.installAndRelaunch() }) {
                                    Label("Neu starten & v\(version) installieren", systemImage: "bolt.fill")
                                }
                                .buttonStyle(ProminentGlassButtonStyle(gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing), cornerRadius: 8))

                            default:
                                EmptyView()
                            }
                        }

                        if case .downloading(let progress, _, _) = appUpdater.state {
                            VStack(alignment: .leading, spacing: 6) {
                                ProgressView(value: progress)
                                    .progressViewStyle(.linear)

                                HStack {
                                    Text(appUpdater.statusMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Abbrechen") {
                                        appUpdater.cancelDownload()
                                    }
                                    .font(.system(size: 11))
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red)
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                        } else if case .extracting = appUpdater.state {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.6)
                                Text(appUpdater.statusMessage)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        } else if !appUpdater.statusMessage.isEmpty {
                            Text(appUpdater.statusMessage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(
                                    {
                                        switch appUpdater.state {
                                        case .error: return .red
                                        case .readyToInstall: return .green
                                        case .available: return .orange
                                        default: return .primary.opacity(0.8)
                                        }
                                    }()
                                )
                        }

                        Divider().opacity(0.15)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Automatische Update-Prüfung")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Prüft beim Start automatisch, ob ein neueres Release auf GitHub vorliegt.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.autoCheckAppUpdates)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Updates automatisch im Hintergrund laden")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Lädt das Release-Paket automatisch vor, sodass du mit einem Klick neu starten kannst.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.autoDownloadAppUpdates)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // Engine & Updates
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Download-Engine & Updates", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14, weight: .bold))

                        HStack {
                            Text("yt-dlp Version: **\(updater.currentVersion)**")
                                .font(.system(size: 13))

                            Spacer()

                            Button(action: { updater.checkForUpdates() }) {
                                if updater.isChecking {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Label("Auf Updates prüfen", systemImage: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                            .disabled(updater.isChecking || updater.isUpdating)

                            if let latest = updater.latestVersion, latest != updater.currentVersion {
                                Button(action: { updater.performUpdate() }) {
                                    if updater.isUpdating {
                                        ProgressView().scaleEffect(0.6)
                                    } else {
                                        Label("Auf \(latest) aktualisieren", systemImage: "arrow.up.circle.fill")
                                    }
                                }
                                .buttonStyle(ProminentGlassButtonStyle(cornerRadius: 8))
                                .disabled(updater.isUpdating)
                            }
                        }

                        if !updater.statusMessage.isEmpty {
                            Text(updater.statusMessage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        Text(updater.ffmpegStatus)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Divider().opacity(0.15)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Automatische Hintergrund-Updates")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Aktualisiert yt-dlp automatisch im Hintergrund, wenn Plattformen Änderungen vornehmen.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.autoUpdateYtDlp)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // Cookies & Authentifizierung
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Browser-Cookies & Login", systemImage: "lock.shield.fill")
                            .font(.system(size: 14, weight: .bold))

                        Text("Aktive Login-Cookies können verwendet werden, um geschützte Inhalte (z.B. Instagram Reels) zuverlässig zu laden.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Picker("Browser für Cookies:", selection: $settings.cookieBrowser) {
                            Text("Keine Cookies (Anonym)").tag("none")
                            Text("Google Chrome").tag("chrome")
                            Text("Mozilla Firefox").tag("firefox")
                            Text("Apple Safari (Festplattenvollzugriff nötig)").tag("safari")
                            Text("Brave Browser").tag("brave")
                            Text("Eigene cookies.txt Datei").tag("custom_file")
                        }

                        if settings.cookieBrowser == "custom_file" {
                            HStack {
                                TextField("Pfad zu cookies.txt...", text: $settings.cookieFilePath)
                                    .textFieldStyle(.roundedBorder)

                                Button(action: chooseCookieFile) {
                                    Label("Datei wählen...", systemImage: "doc")
                                }
                                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8))
                            }
                        }

                        Divider().opacity(0.3)

                        Text("Cookies auf folgenden Plattformen verwenden:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)

                        Toggle("Instagram (Empfohlen für Reels)", isOn: $settings.useCookiesInstagram)
                        Toggle("YouTube (Standard: aus, da Google oft Bot-Prüfungen triggert)", isOn: $settings.useCookiesYouTube)
                        Toggle("Twitch", isOn: $settings.useCookiesTwitch)
                        Toggle("Universal / Sonstige", isOn: $settings.useCookiesUniversal)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // Medien Optionen
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Mediendatei-Optionen", systemImage: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .bold))

                        Toggle("Automatisch in H.265 (HEVC) umwandeln (Apple Silicon)", isOn: $settings.convertToH265)
                        Toggle("Thumbnail als Cover-Bild in Datei einbetten", isOn: $settings.embedThumbnail)
                        Toggle("Metadaten & Kapitel einbetten", isOn: $settings.embedMetadata)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // macOS Benachrichtigungen
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("macOS Benachrichtigungen", systemImage: "bell.badge.fill")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            if notifications.authorizationStatus == .authorized {
                                Label("Aktiviert", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                            } else {
                                Label("Ausstehend / Erlaubnis nötig", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mitteilung bei fertigem Download")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("Sendet einen Banner mit Ton und Direktbutton „Im Finder anzeigen“.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $settings.sendDownloadNotification)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }

                        Divider().opacity(0.15)

                        HStack(spacing: 10) {
                            if notifications.authorizationStatus != .authorized {
                                Button(action: { notifications.requestAuthorization() }) {
                                    Label("Mitteilungen erlauben", systemImage: "hand.raised.fill")
                                }
                                .buttonStyle(ProminentGlassButtonStyle(
                                    gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    cornerRadius: 8,
                                    horizontalPadding: 10,
                                    verticalPadding: 6
                                ))

                                Button(action: { notifications.openSystemNotificationSettings() }) {
                                    Label("In Systemeinstellungen öffnen", systemImage: "gearshape")
                                }
                                .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8, horizontalPadding: 10, verticalPadding: 6))
                            }

                            Button(action: { notifications.sendTestNotification() }) {
                                Label("Test-Mitteilung senden", systemImage: "bell.and.waveform")
                            }
                            .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8, horizontalPadding: 10, verticalPadding: 6))
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)

                    // Über ripr & Versionsinfo
                    HStack(spacing: 14) {
                        BrandIconView(
                            platform: nil,
                            customName: "rlogo",
                            fallbackSymbol: "sparkles",
                            size: 28,
                            color: .white
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text("ripr")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)

                                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                            }

                            Text("100% nativ für Apple Silicon (ARM64) • Erstellt von Lennart")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.regularMaterial.opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
                .frame(maxWidth: 640)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .background(ScrollbarHider())
        }
        .removeScrollBars()
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.downloadFolder
        if panel.runModal() == .OK, let url = panel.url {
            settings.downloadFolder = url
        }
    }

    private func chooseCookieFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            settings.cookieFilePath = url.path
        }
    }
}

// MARK: - Floating Liquid Glass Tab Bar (SF Symbols)
public struct GlassTabBar: View {
    @Binding var selectedTab: String
    @ObservedObject private var appUpdater = AppUpdaterService.shared

    let tabs: [(id: String, name: String, icon: String)] = [
        ("Download", "Download", "sparkles"),
        ("History", "Historie", "clock.arrow.circlepath"),
        ("Settings", "Einstellungen", "gearshape.fill")
    ]

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.id) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        selectedTab = tab.id
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))

                        Text(tab.name)
                            .font(.system(size: 13, weight: selectedTab == tab.id ? .bold : .medium))

                        if tab.id == "Settings" && (appUpdater.latestVersion != nil && appUpdater.latestVersion != appUpdater.currentVersion) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(selectedTab == tab.id ? .white : .primary.opacity(0.75))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Group {
                            if selectedTab == tab.id {
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.85))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                                    )
                                    .shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 3)
                            } else {
                                Capsule()
                                    .fill(Color.white.opacity(0.001))
                            }
                        }
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 14, x: 0, y: 5)
    }
}

// MARK: - App Update Banner View
public struct AppUpdateBannerView: View {
    @ObservedObject private var appUpdater = AppUpdaterService.shared

    public var body: some View {
        if appUpdater.showBanner {
            Group {
                switch appUpdater.state {
                case .available(let version, _, _):
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neues ripr Update verfügbar (v\(version))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Ein neues Release steht auf GitHub bereit.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { appUpdater.startDownload() }) {
                            Label("Laden & Installieren", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(ProminentGlassButtonStyle(cornerRadius: 8, horizontalPadding: 10, verticalPadding: 5))

                        Button(action: {
                            withAnimation { appUpdater.showBanner = false }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.3)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))

                case .downloading(let progress, _, _):
                    HStack(spacing: 12) {
                        ProgressView().scaleEffect(0.65)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(appUpdater.statusMessage)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)

                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .frame(maxWidth: 320)
                        }

                        Spacer()

                        Button("Abbrechen") {
                            appUpdater.cancelDownload()
                        }
                        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8, horizontalPadding: 10, verticalPadding: 5))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))

                case .extracting:
                    HStack(spacing: 12) {
                        ProgressView().scaleEffect(0.65)
                        Text(appUpdater.statusMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)

                case .readyToInstall(let version):
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("ripr v\(version) ist heruntergeladen!")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Starte die App neu, um das Update zu installieren.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { appUpdater.installAndRelaunch() }) {
                            Label("Jetzt neu starten", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(ProminentGlassButtonStyle(
                            gradient: LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                            cornerRadius: 8,
                            horizontalPadding: 12,
                            verticalPadding: 6
                        ))

                        Button(action: {
                            withAnimation { appUpdater.showBanner = false }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(colors: [Color.green.opacity(0.8), Color.teal.opacity(0.4)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.2)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))

                default:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: appUpdater.state)
        }
    }
}

// MARK: - In-App Download Finished Toast
public struct InAppDownloadToastView: View {
    @ObservedObject private var notifications = NotificationService.shared

    public var body: some View {
        Group {
            if notifications.showInAppToast, let item = notifications.latestFinishedDownload {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Download abgeschlossen")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("ripr")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }

                        Text(item.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: {
                            notifications.showInFinder(atPath: item.filePath)
                        }) {
                            Label("Im Finder anzeigen", systemImage: "folder")
                        }
                        .buttonStyle(ProminentGlassButtonStyle(
                            gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                            cornerRadius: 8,
                            horizontalPadding: 10,
                            verticalPadding: 6
                        ))

                        Button(action: {
                            notifications.openFile(atPath: item.filePath)
                        }) {
                            Label("Öffnen", systemImage: "arrow.up.right")
                        }
                        .buttonStyle(LiquidGlassButtonStyle(cornerRadius: 8, horizontalPadding: 10, verticalPadding: 6))

                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                notifications.showInAppToast = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.4), Color.white.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 6)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: notifications.showInAppToast)
    }
}

// MARK: - Main Content View (Liquid Glass Shell)
public struct ContentView: View {
    @ObservedObject private var router = TabRouter.shared

    public var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Obere schwebende Liquid-Glass Leiste
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                    }
                    .frame(height: 14)

                    GlassTabBar(selectedTab: $router.selectedTab)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                AppUpdateBannerView()

                // Tab Content
                Group {
                    switch router.selectedTab {
                    case "Download":
                        AutoDownloaderView()
                    case "History":
                        HistoryView()
                    case "Settings":
                        SettingsView()
                    default:
                        AutoDownloaderView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scrollIndicators(.hidden)
            }

            // In-App Toast Overlay unten
            VStack {
                Spacer()
                InAppDownloadToastView()
            }
        }
        .frame(width: 900, height: 680)
        .background(ScrollbarHider())
        .removeScrollBars()
    }
}
