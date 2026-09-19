#!/bin/bash
set -e
cd "$(dirname "$0")"

VERSION="$1"
TITLE="$2"
NOTES="$3"

if [ -z "$VERSION" ]; then
    echo "❌ Fehler: Keine Versionsnummer angegeben!"
    echo "Verwendung: ./release.sh <VERSION> [TITLE] [NOTES]"
    echo "Beispiel:   ./release.sh 1.0.1 \"ripr v1.0.1\" \"Versionsanzeige & Stabilitätsverbesserungen\""
    exit 1
fi

TAG="v${VERSION#v}" # Garantiert das Format 'v1.0.1'
VERSION_CLEAN="${VERSION#v}" # Garantiert '1.0.1' ohne führendes 'v'

if [ -z "$TITLE" ]; then
    TITLE="ripr ${TAG}"
fi

if [ -z "$NOTES" ]; then
    NOTES="Automatisch veröffentlichtes Release für ripr ${TAG}."
fi

echo "========================================="
echo "🚀 Starte 100% automatischen Release-Prozess für ${TAG}"
echo "Titel: ${TITLE}"
echo "========================================="

# 1. Versionsnummer in SwiftApp/Info.plist aktualisieren
echo "📝 Aktualisiere Info.plist auf Version ${VERSION_CLEAN}..."
sed -i '' "s/<string>[0-9]*\.[0-9]*\.[0-9]*<\/string>/<string>${VERSION_CLEAN}<\/string>/g" SwiftApp/Info.plist

# 2. App kompilieren
echo "🔨 Kompiliere App..."
./build_swift.sh

# 3. ripr.dmg erstellen
echo "💿 Erstelle DMG..."
./create_dmg.sh

# 4. Änderungen comitten
echo "📦 Erstelle Git Commit..."
git add SwiftApp/Info.plist SwiftApp/Sources/ CHANGELOG.md 2>/dev/null || true
git commit -m "Release ${TAG}: ${TITLE}" || echo "Keine Code-Änderungen zu committen."

# 5. Git Tag lokal erstellen (ggf. alten Tag überschreiben)
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "⚠️ Tag $TAG existiert bereits lokal – wird aktualisiert..."
    git tag -d "$TAG" >/dev/null 2>&1 || true
fi
git tag -a "$TAG" -m "${TITLE}"

# 6. Push zu GitHub (main branch und tag)
echo "☁️ Pushe Code und Tag ${TAG} zu GitHub..."
git push origin main
git push origin "$TAG" --force

# 7. GitHub Token aus dem macOS Schlüsselbund beziehen
echo "🔑 Hole GitHub-Zugangsdaten aus dem macOS-Schlüsselbund..."
TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill 2>/dev/null | grep '^password=' | cut -d= -f2)

if [ -z "$TOKEN" ]; then
    echo "❌ Fehler: Konnte GitHub-Token nicht aus dem macOS Schlüsselbund lesen."
    echo "Bitte stelle sicher, dass deine Zugangsdaten im Terminal gespeichert sind."
    exit 1
fi

REPO="lennart168/ripr"

# 8. Prüfen ob Release bereits existiert
echo "🔍 Prüfe existierendes GitHub Release für ${TAG}..."
RELEASE_DATA=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/${REPO}/releases/tags/${TAG}")
RELEASE_ID=$(echo "$RELEASE_DATA" | grep '"id":' | head -n 1 | awk '{print $2}' | tr -d ',')

if [ -n "$RELEASE_ID" ] && [ "$RELEASE_ID" != "null" ] && [ "$RELEASE_ID" != "" ]; then
    echo "ℹ️ Release für ${TAG} existiert bereits (ID: ${RELEASE_ID}). Lösche vorheriges DMG Asset..."
    ASSET_ID=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.argv[1])
    for a in data.get("assets", []):
        if a.get("name") == "ripr.dmg":
            print(a.get("id", ""))
            break
except Exception:
    pass
' "$RELEASE_DATA")
    if [ -n "$ASSET_ID" ]; then
        curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/${REPO}/releases/assets/${ASSET_ID}"
    fi
else
    echo "✨ Erstelle neues GitHub Release für ${TAG}..."
    JSON_PAYLOAD=$(python3 -c '
import json, sys
tag = sys.argv[1]
title = sys.argv[2]
notes = sys.argv[3]
print(json.dumps({
    "tag_name": tag,
    "name": title,
    "body": notes,
    "draft": False,
    "prerelease": False
}))
' "$TAG" "$TITLE" "$NOTES")

    RELEASE_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${REPO}/releases" \
        -d "$JSON_PAYLOAD")

    RELEASE_ID=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.argv[1])
    print(data.get("id") or "")
except Exception:
    pass
' "$RELEASE_RESPONSE")
fi

if [ -z "$RELEASE_ID" ] || [ "$RELEASE_ID" = "null" ]; then
    echo "❌ Fehler beim Erstellen des Releases via GitHub API!"
    echo "$RELEASE_RESPONSE"
    exit 1
fi

# 9. ripr.dmg als Release Asset hochladen
echo "⬆️ Lade ripr.dmg auf GitHub Releases hoch (ca. 99 MB)..."
UPLOAD_URL="https://uploads.github.com/repos/${REPO}/releases/${RELEASE_ID}/assets?name=ripr.dmg"

UPLOAD_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"ripr.dmg" \
    "$UPLOAD_URL")

DOWNLOAD_URL=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.argv[1])
    print(data.get("browser_download_url") or "")
except Exception:
    pass
' "$UPLOAD_RESPONSE")

echo "========================================="
echo "🎉 ERFOLG! Release ${TAG} ist ab sofort live!"
echo "🌐 Release-Seite:   https://github.com/${REPO}/releases/tag/${TAG}"
if [ -n "$DOWNLOAD_URL" ]; then
    echo "📥 Direkter Download: ${DOWNLOAD_URL}"
fi
echo "========================================="
