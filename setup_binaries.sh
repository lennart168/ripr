#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "========================================="
echo "📥 ripr - Binaries Downloader"
echo "========================================="

mkdir -p Binaries

# 1. yt-dlp_macos (Universal Binary mit integriertem Python)
if [ ! -f "Binaries/yt-dlp" ]; then
    echo "⬇️ Lade eigenständiges yt-dlp (macOS Universal)..."
    curl -L --progress-bar -o Binaries/yt-dlp https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos
    chmod +x Binaries/yt-dlp
else
    echo "✓ Binaries/yt-dlp bereits vorhanden."
fi

# 2. Statisches ffmpeg (ARM64)
if [ ! -f "Binaries/ffmpeg" ]; then
    echo "⬇️ Lade statisches FFmpeg (Apple Silicon ARM64)..."
    curl -L --progress-bar -o /tmp/ripr_ffmpeg.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip
    unzip -q -o /tmp/ripr_ffmpeg.zip -d Binaries/
    rm -f /tmp/ripr_ffmpeg.zip
    chmod +x Binaries/ffmpeg
else
    echo "✓ Binaries/ffmpeg bereits vorhanden."
fi

# 3. Statisches ffprobe (ARM64)
if [ ! -f "Binaries/ffprobe" ]; then
    echo "⬇️ Lade statisches FFprobe (Apple Silicon ARM64)..."
    curl -L --progress-bar -o /tmp/ripr_ffprobe.zip https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffprobe.zip
    unzip -q -o /tmp/ripr_ffprobe.zip -d Binaries/
    rm -f /tmp/ripr_ffprobe.zip
    chmod +x Binaries/ffprobe
else
    echo "✓ Binaries/ffprobe bereits vorhanden."
fi

echo "========================================="
echo "✅ Alle Binaries sind einsatzbereit!"
echo "Führe nun './build_swift.sh' oder './create_dmg.sh' aus."
echo "========================================="
