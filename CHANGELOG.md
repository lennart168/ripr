# 📋 ripr — Changelog & Release Notes

Hier werden alle Änderungen, neuen Funktionen und Fehlerbehebungen nach jedem Release protokolliert. Sobald ein neues Release ansteht, werden diese Notizen direkt für die GitHub Release Notes verwendet.

---

## 📦 [v1.1.0] — 2026-09-19

### 📑 Playlists & Sammlungen herunterladen
- **Intelligente Playlist-Erkennung**: Erkennt reine Playlist-Links sowie Kombinations-URLs (Video + Playlist) automatisch bei YouTube, SoundCloud und weiteren Plattformen.
- **Kombi-Link Switcher**: Erlaubt die intuitive Wahl zwischen „Nur dieses Video laden“ und „Ganze Playlist laden“.
- **Neue Master Playlist Card**:
  - Übersichtliche Darstellung von Cover, Gesamttitel, Uploader, Gesamtspielzeit und Track-Anzahl.
  - Modus-Umschaltung für **Video** (Beste Qualität, 1080p, 720p, etc.) und **Audio** (MP3 320 kbps, M4A, FLAC, WAV).
  - Schnellauswahl mit Buttons **„Alle“** und **„Keine“** sowie individuelle Track-Auswahl per Checkbox.
  - Optionale Speicherung im eigenen Unterordner sowie automatische Durchnummerierung (`01 - Title.mp4`).
- **Zuverlässiger Playlist-Download**: Engine erkennt erfolgreiche Downloads auch dann, wenn einzelne geschützte oder gelöschte Tracks von yt-dlp übersprungen wurden.

### 🔔 macOS Benachrichtigungen & Finder-Integration
- **Fertigstellungs-Mitteilung**: Sendet eine native macOS-Benachrichtigung mit Ton, sobald ein Download oder eine Playlist abgeschlossen ist.
- **In-App Toast**: Schwebendes Glass-Banner mit Schnellzugriff („Im Finder anzeigen“ / „Öffnen“).
- **Direktzugriff im Finder**: Ein Klick auf „Im Finder anzeigen“ öffnet bei Playlists direkt den neuen Zielordner mit allen Dateien.
- **AppleScript-Fallback**: Garantiert visuelle Rückmeldung selbst dann, wenn macOS-Mitteilungen in den Systemeinstellungen noch nicht manuell freigegeben wurden.

### 📜 Download-Historie für Playlists & Tracks
- Alle Downloads und Playlists werden automatisch mit Datum, Plattform, Format und Dateianzahl in der Historie festgehalten.
- Playlists erhalten ein eigenes Ordnersymbol und können direkt aus der Historie im Finder geöffnet werden.

### 🎨 Design & Scrollbar-Polishing
- **Plattform-Farben für Playlists**: Die Playlist-Karte übernimmt die native Farbe der Plattform (z. B. originales **YouTube-Rot** `#FF0000` für Badge, Auswahl-Häkchen, Ladebalken und Download-Button).
- **Unsichtbare Scrollbalken**: Aufhebung störender macOS-Scrollbalken auf AppKit-Ebene (`ScrollbarHider`) für eine makellose Optik bei uneingeschränkter Mausrad- und Trackpad-Bedienung.

---

## 📦 [v1.0.2] — 2026-09-19

### 🔄 Automatisches App-Update-System (GitHub Releases)
- **Natives Auto-Update**: ripr erkennt nun automatisch neue GitHub-Releases (`lennart168/ripr`), lädt das Release-Paket (`ripr.dmg`) mit Live-Fortschrittsbalken im Hintergrund herunter, entpackt es geräuschlos und ersetzt die alte App nahtlos.
- **Schwebender Update-Banner**: Erscheint direkt in der App, sobald ein Update vorliegt oder heruntergeladen wurde – mit Ein-Klick-Installation ("Jetzt neu starten & aktualisieren").
- **App-Update-Verwaltung in den Einstellungen**: Neue Karte zur manuellen und automatischen Update-Prüfung inklusive Konfigurationsschaltern für Hintergrund-Downloads.
- **Gatekeeper-Quarantäne-Bereinigung**: Automatische Bereinigung (`xattr -cr`), damit aktualisierte Apps ohne Sicherheitswarnungen starten.

### 🎨 Design & UI
- **Startseite aufgeräumt**: Versionsplakette von der Startseite entfernt für einen noch minimalistischeren, cleanen Look.
- **Zentraler Versionsort**: Versionsanzeige übersichtlich und exklusiv in den Einstellungen gebündelt.
- **Indikator im Einstellungs-Tab**: Subtiler Hinweis-Punkt bei verfügbaren Aktualisierungen.

---

## 📦 [v1.0.1] — 2026-09-19

### 📦 Standalone Binaries & Engine
- **100% Standalone (Apple Silicon)**: Eigenständige, native Apple Silicon (ARM64) Binaries für `yt-dlp`, `ffmpeg` und `ffprobe` fest ins App-Bundle integriert. Nutzer benötigen weder Homebrew noch Python auf ihrem Mac.
- **Stiller yt-dlp Background-Updater**: Aktualisiert die Engine automatisch im Hintergrund (alle 12 Stunden gedrosselt).
- **YouTube 360p Fix**: Höchste Videoauflösungen (4K, 1440p, 1080p, 720p) wieder uneingeschränkt verfügbar.

### 🎨 Design & UI
- **Format- & Qualitäts-Dropdowns**: Verbreiterte Dropdown-Menüs direkt neben dem Thumbnail auf voller Zeilenbreite für optimale Übersicht.
- **Plattform-adaptiver Analysieren-Button**: Dynamische Übernahme der Markenfarben (YouTube Rot, TikTok Cyan, Kick Neon, etc.) mit angepassten Textkontrasten.

### ⚙️ Pipeline & Automatisierung
- **1-Klick GitHub Release Pipeline**: Skript `release.sh` zur automatischen Versionierung, Kompilierung, DMG-Erstellung und Release-Veröffentlichung.
- **Changelog-Tracking**: Zentrale Erfassung aller Versionsschritte direkt im Repository.

---

## 📦 [v1.0.0] — 2026-09-19
- Initiales öffentliches Release von **ripr** als native macOS SwiftUI App.
- Multi-Plattform-Unterstützung (YouTube, TikTok, Instagram, Twitch, Universal).
- Twitch Live-Stream Recording in Echtzeit.
- Drag & Drop macOS Installations-Image (`ripr.dmg`).
