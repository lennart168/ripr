import subprocess
import sys
import shutil
import requests
from typing import Tuple, Optional

class EngineUpdater:
    @staticmethod
    def get_current_ytdlp_version() -> str:
        """Gibt die aktuell installierte yt-dlp Version zurück."""
        try:
            import yt_dlp
            return yt_dlp.version.__version__
        except Exception:
            try:
                res = subprocess.run([sys.executable, "-m", "yt_dlp", "--version"], 
                                     capture_output=True, text=True, timeout=5)
                if res.returncode == 0:
                    return res.stdout.strip()
            except Exception:
                pass
        return "Unbekannt"

    @staticmethod
    def get_latest_ytdlp_version() -> Tuple[Optional[str], Optional[str]]:
        """
        Fragt die neueste Version von yt-dlp über die GitHub API ab.
        Gibt (latest_version, release_notes_url) zurück.
        """
        try:
            url = "https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
            headers = {"User-Agent": "lennartlol-downloader"}
            resp = requests.get(url, headers=headers, timeout=8)
            if resp.status_code == 200:
                data = resp.json()
                tag = data.get("tag_name", "").lstrip("v")
                html_url = data.get("html_url", "")
                return tag, html_url
        except Exception as e:
            print(f"Update-Check-Fehler: {e}")
        return None, None

    @staticmethod
    def update_ytdlp() -> Tuple[bool, str]:
        """
        Führt ein Update von yt-dlp durch.
        Nutzt 'pip install --upgrade yt-dlp'.
        """
        try:
            cmd = [sys.executable, "-m", "pip", "install", "--upgrade", "yt-dlp"]
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
            if proc.returncode == 0:
                new_ver = EngineUpdater.get_current_ytdlp_version()
                return True, f"Erfolgreich auf Version {new_ver} aktualisiert!"
            else:
                return False, f"Update fehlgeschlagen:\n{proc.stderr or proc.stdout}"
        except Exception as e:
            return False, f"Fehler beim Ausführen des Updates: {e}"

    @staticmethod
    def check_ffmpeg() -> Tuple[bool, str]:
        """
        Prüft, ob FFmpeg auf dem System vorhanden ist und gibt die Version zurück.
        """
        ffmpeg_path = shutil.which("ffmpeg")
        if not ffmpeg_path:
            # Häufige Pfade auf macOS prüfen
            for candidate in ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]:
                if shutil.which(candidate):
                    ffmpeg_path = candidate
                    break

        if not ffmpeg_path:
            return False, "FFmpeg nicht gefunden! Bitte installiere es via Homebrew ('brew install ffmpeg')."

        try:
            proc = subprocess.run([ffmpeg_path, "-version"], capture_output=True, text=True, timeout=5)
            first_line = proc.stdout.splitlines()[0] if proc.stdout else "Gefunden"
            return True, f"{first_line} ({ffmpeg_path})"
        except Exception as e:
            return True, f"FFmpeg gefunden unter {ffmpeg_path}, Fehler beim Versionsabruf: {e}"
