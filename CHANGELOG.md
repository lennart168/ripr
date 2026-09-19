# 📋 ripr — Changelog & Release Notes

Hier werden alle Änderungen, neuen Funktionen und Fehlerbehebungen nach jedem Release protokolliert. Sobald ein neues Release ansteht, werden diese Notizen direkt für die GitHub Release Notes verwendet.

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
