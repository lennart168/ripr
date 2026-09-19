#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="ripr"
APP_BUNDLE="${APP_NAME}.app"

echo "🔨 Kompiliere native Swift / SwiftUI macOS App ($APP_NAME)..."
mkdir -p SwiftApp/BuildCache
swiftc -target arm64-apple-macosx14.0 -module-cache-path SwiftApp/BuildCache -parse-as-library SwiftApp/Sources/*.swift -o "SwiftApp/${APP_NAME}"

echo "📦 Erstelle ${APP_BUNDLE} Bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"
cp "SwiftApp/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

if [ -f "SwiftApp/Info.plist" ]; then
    cp "SwiftApp/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
fi

# macOS AppIcon.icns automatisch aus Master-PNG generieren
ICON_SRC=""
if [ -f "Icons/Icon-iOS-Default-1024@1x.png" ]; then
    ICON_SRC="Icons/Icon-iOS-Default-1024@1x.png"
elif [ -f "Icons/AppIcon.png" ]; then
    ICON_SRC="Icons/AppIcon.png"
fi

if [ -n "$ICON_SRC" ]; then
    echo "🎨 Erstelle Apple AppIcon.icns aus $ICON_SRC..."
    TMP_ICONSET=$(mktemp -d)/AppIcon.iconset
    mkdir -p "$TMP_ICONSET"
    sips -z 16 16     "$ICON_SRC" --out "$TMP_ICONSET/icon_16x16.png" >/dev/null 2>&1
    sips -z 32 32     "$ICON_SRC" --out "$TMP_ICONSET/icon_16x16@2x.png" >/dev/null 2>&1
    sips -z 32 32     "$ICON_SRC" --out "$TMP_ICONSET/icon_32x32.png" >/dev/null 2>&1
    sips -z 64 64     "$ICON_SRC" --out "$TMP_ICONSET/icon_32x32@2x.png" >/dev/null 2>&1
    sips -z 128 128   "$ICON_SRC" --out "$TMP_ICONSET/icon_128x128.png" >/dev/null 2>&1
    sips -z 256 256   "$ICON_SRC" --out "$TMP_ICONSET/icon_128x128@2x.png" >/dev/null 2>&1
    sips -z 256 256   "$ICON_SRC" --out "$TMP_ICONSET/icon_256x256.png" >/dev/null 2>&1
    sips -z 512 512   "$ICON_SRC" --out "$TMP_ICONSET/icon_256x256@2x.png" >/dev/null 2>&1
    sips -z 512 512   "$ICON_SRC" --out "$TMP_ICONSET/icon_512x512.png" >/dev/null 2>&1
    sips -z 1024 1024 "$ICON_SRC" --out "$TMP_ICONSET/icon_512x512@2x.png" >/dev/null 2>&1
    iconutil -c icns "$TMP_ICONSET" -o "Icons/AppIcon.icns"
    rm -rf "$(dirname "$TMP_ICONSET")"
fi

# Echte Icons kopieren & SVGs automatisch zu hochauflösendem Retina-PNG konvertieren
if [ -d "Icons" ]; then
    for svg in Icons/*.svg; do
        if [ -f "$svg" ]; then
            base="${svg%.svg}"
            sips -s format png -z 512 512 "$svg" --out "${base}.png" 2>/dev/null || true
        fi
    done
    if [ -f "Icons/rlogo.png" ]; then
        cp "Icons/rlogo.png" "Icons/logo.png" 2>/dev/null || true
    fi
    cp -R Icons/* "${APP_BUNDLE}/Contents/Resources/" 2>/dev/null || true
fi

# Eigenständige Binaries (yt-dlp, ffmpeg, ffprobe) ins Bundle packen
if [ -d "Binaries" ]; then
    echo "📦 Bündele eigenständige Binaries (yt-dlp, ffmpeg, ffprobe)..."
    mkdir -p "${APP_BUNDLE}/Contents/Resources/bin"
    cp -f Binaries/* "${APP_BUNDLE}/Contents/Resources/bin/"
    chmod +x "${APP_BUNDLE}/Contents/Resources/bin/"*
    xattr -cr "${APP_BUNDLE}/Contents/Resources/bin/"* 2>/dev/null || true
    for b in "${APP_BUNDLE}/Contents/Resources/bin/"*; do
        if [ -f "$b" ]; then
            codesign --force -s - "$b" 2>/dev/null || true
        fi
    done
fi

codesign --force --deep -s - "${APP_BUNDLE}"
xattr -cr "${APP_BUNDLE}"
touch "${APP_BUNDLE}"

# Auch altes Bundle aktualisieren falls der User es noch im Dock/Ordner anklickt
if [ -d "lennartlol Downloader.app" ]; then
    rm -rf "lennartlol Downloader.app"
    cp -R "${APP_BUNDLE}" "lennartlol Downloader.app"
    codesign --force --deep -s - "lennartlol Downloader.app" 2>/dev/null || true
fi

echo "✅ Fertig! Die App '${APP_BUNDLE}' ist bereit."
