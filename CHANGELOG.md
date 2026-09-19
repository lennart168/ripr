# 📋 ripr — Changelog & Release Notes

Hier werden alle Änderungen, neuen Funktionen und Fehlerbehebungen nach jedem Release protokolliert. Sobald ein neues Release ansteht, werden diese Notizen direkt für die GitHub Release Notes verwendet.

---

## 🚀 [Unreleased] (Geplant für das nächste Release)

### 🎨 Design & UI
- **Startseite aufgeräumt**: Die Versionsplakette wurde von der Startseite neben dem Haupttitel entfernt für einen noch minimalistischeren, cleanen Look.
- **Zentraler Versionsort**: Die Versionsnummer (`v1.0.1` etc.) ist nun exklusiv und übersichtlich ganz unten im Tab **Einstellungen** in der System-Infokarte zu finden.

### ⚙️ Automatisierung & System
- **1-Klick GitHub Release Pipeline**: Vollautomatisiertes Skript `release.sh`, das per Befehl das Projekt baut, signiert, taggt und das fertige `.dmg` direkt zu GitHub Releases hochlädt.
- **Changelog-Tracking**: Zentrale Erfassung aller Zwischenschritte für saubere Release-Notizen.

---

## 📦 [v1.0.1] — 2026-09-19
- **Standalone Binaries**: Eigenständige, native Apple Silicon (ARM64) Binaries für `yt-dlp`, `ffmpeg` und `ffprobe` fest ins App-Bundle integriert. Nutzer benötigen weder Homebrew noch Python.
- **Stiller Background-Updater**: Automatischer, lautloser Check für `yt-dlp` im Hintergrund (alle 12 Stunden gedrosselt).
- **Format- & Qualitäts-Dropdowns**: Verbreiterte Dropdown-Menüs direkt neben dem Thumbnail auf voller Zeilenbreite.
- **Plattform-adaptiver Analysieren-Button**: Dynamische Übernahme der Markenfarben und angepasste Textfarben (z. B. schwarz auf hellem TikTok/Kick).
- **YouTube 360p Fix**: Volle Videoauflösungen (4K, 1440p, 1080p, 720p) wieder uneingeschränkt verfügbar.

---

## 📦 [v1.0.0] — 2026-09-19
- Initiales öffentliches Release von **ripr** als native macOS SwiftUI App.
- Multi-Plattform-Unterstützung (YouTube, TikTok, Instagram, Twitch, Universal).
- Twitch Live-Stream Recording in Echtzeit.
- Drag & Drop macOS Installations-Image (`ripr.dmg`).
