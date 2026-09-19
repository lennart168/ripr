#!/bin/bash
set -e
cd "$(dirname "$0")"

APP_NAME="ripr"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="dist_dmg"

echo "========================================="
echo "💿 Erstelle macOS Disk Image (.dmg) für ${APP_NAME}..."
echo "========================================="

# 1. App kompilieren / aktualisieren
echo "🔨 Stelle sicher, dass die App aktuell gebaut ist..."
./build_swift.sh

# 2. Temporären Staging-Ordner vorbereiten
echo "📁 Bereite DMG-Inhalt vor..."
rm -rf "$STAGING_DIR" "$DMG_NAME"
mkdir -p "$STAGING_DIR"

# 3. ripr.app hineinkopieren
echo "📦 Kopiere ${APP_NAME}.app in das Image..."
cp -R "${APP_NAME}.app" "$STAGING_DIR/"

# 4. Symlink auf /Applications erstellen (Drag & Drop Installation)
echo "🔗 Erstelle Verknüpfung zu /Applications..."
ln -s /Applications "$STAGING_DIR/Applications"

# 5. .dmg mit hdiutil generieren (komprimiertes UDZO Format)
echo "💿 Generiere ${DMG_NAME} mit hdiutil..."
hdiutil create -volname "${APP_NAME}" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# 6. Aufräumen
rm -rf "$STAGING_DIR"

# 7. Ad-hoc Codesigning für das DMG
echo "✍️ Signiere ${DMG_NAME} (Ad-hoc)..."
codesign --force -s - "$DMG_NAME" 2>/dev/null || true

SIZE=$(du -h "$DMG_NAME" | cut -f1)
echo "========================================="
echo "🎉 ERFOLG! '${DMG_NAME}' (${SIZE}) wurde erfolgreich erstellt!"
echo "Du kannst diese Datei jetzt:"
echo " 1. Per Doppelklick testen (öffnet sich wie ein normales Installationsfenster)."
echo " 2. Auf GitHub unter Releases -> 'New Release' hochladen."
echo "========================================="
