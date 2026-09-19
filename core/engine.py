import os
import re
import sys
import time
import signal
import subprocess
from typing import Optional, List
from PySide6.QtCore import QThread, Signal
from .config import config

PROGRESS_FALLBACK_REGEX = re.compile(
    r"\[download\]\s+([0-9\.]+)%\s+of\s+(?:~?\s*([0-9\.]+[a-zA-Z]+))(?:\s+at\s+([0-9\.]+[a-zA-Z]+/s))?(?:\s+ETA\s+([0-9:]+))?"
)

class DownloadWorker(QThread):
    progress_changed = Signal(float, str, str, str)  # percent, speed, eta, downloaded_size
    status_changed = Signal(str)                      # status text
    download_finished = Signal(str)                   # output file path
    download_error = Signal(str)                      # error message

    def __init__(
        self,
        url: str,
        output_dir: str,
        platform_name: str = "Universal",
        mode: str = "video",
        video_selector: str = "bestvideo+bestaudio/best",
        audio_format: str = "mp3",
        audio_quality: str = "0",
        is_live: bool = False
    ):
        super().__init__()
        self.url = url
        self.output_dir = output_dir or config.get("download_dir", os.path.expanduser("~/Downloads"))
        self.platform_name = platform_name
        self.mode = mode
        self.video_selector = video_selector
        self.audio_format = audio_format
        self.audio_quality = audio_quality
        self.is_live = is_live
        
        self._process: Optional[subprocess.Popen] = None
        self._is_cancelled = False
        self._is_stopping_live = False
        self.final_filename = ""
        self.start_time = 0.0

    def cancel(self):
        """Bricht den Download oder die Live-Aufnahme sauber ab."""
        self._is_cancelled = True
        if self._process and self._process.poll() is None:
            try:
                if self.is_live:
                    self._is_stopping_live = True
                    self.status_changed.emit("Live-Aufnahme wird finalisiert & gespeichert...")
                    self._process.send_signal(signal.SIGINT)
                else:
                    self.status_changed.emit("Download wird abgebrochen...")
                    self._process.send_signal(signal.SIGINT)
                    time.sleep(0.8)
                    if self._process and self._process.poll() is None:
                        self._process.terminate()
            except Exception as e:
                print(f"Fehler beim Senden des Abbruch-Signals: {e}")

    def _build_command(self, use_cookies: bool = True) -> List[str]:
        cmd = [
            sys.executable, "-m", "yt_dlp",
            "--newline",
            "--no-part",
            "--remote-components", "ejs:github",
            "--progress-template", "download:DOWNLOAD_PROGRESS:%(progress._percent_str)s|%(progress._total_bytes_str,progress._total_bytes_estimate_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._downloaded_bytes_str)s",
        ]

        # Cookie Konfiguration
        if use_cookies:
            browser, cookie_file = config.get_cookie_settings_for_platform(self.platform_name)
            if browser and browser != "none":
                if browser == "custom_file" and cookie_file and os.path.exists(cookie_file):
                    cmd.extend(["--cookiefile", cookie_file])
                elif browser in ["safari", "chrome", "firefox", "brave", "edge"]:
                    cmd.extend(["--cookies-from-browser", browser])

        os.makedirs(self.output_dir, exist_ok=True)
        outtmpl = os.path.join(self.output_dir, "%(title)s [%(id)s].%(ext)s")
        cmd.extend(["-o", outtmpl])

        if self.mode == "audio":
            cmd.extend([
                "-x",
                "--audio-format", self.audio_format,
                "--audio-quality", self.audio_quality,
            ])
            if config.get("embed_thumbnail", True):
                cmd.append("--embed-thumbnail")
            if config.get("embed_metadata", True):
                cmd.append("--embed-metadata")
        else:
            if self.is_live:
                cmd.extend(["-f", self.video_selector or "best"])
                cmd.extend(["--hls-use-mpegts"])
            else:
                cmd.extend(["-f", self.video_selector])
                cmd.extend(["--merge-output-format", "mp4"])
                if config.get("embed_thumbnail", True):
                    cmd.append("--embed-thumbnail")
                if config.get("embed_metadata", True):
                    cmd.append("--embed-metadata")

        cmd.append(self.url)
        return cmd

    def run(self):
        self.start_time = time.time()
        self.status_changed.emit("Initialisiere Download...")

        cmd = self._build_command(use_cookies=True)
        success = self._execute_process(cmd)

        if not success and not self._is_cancelled:
            self.status_changed.emit("Wiederhole ohne Cookies...")
            cmd_fallback = self._build_command(use_cookies=False)
            self._execute_process(cmd_fallback)

    def _execute_process(self, cmd: List[str]) -> bool:
        dest_file_candidate = ""
        captured_error = ""

        try:
            self._process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            last_live_update = 0.0

            while True:
                line = self._process.stdout.readline()
                if not line:
                    break

                line = line.strip()
                if not line:
                    continue

                # Datei-Pfade erfassen
                if "[download] Destination:" in line:
                    dest_file_candidate = line.split("Destination:", 1)[1].strip()
                    self.final_filename = dest_file_candidate
                    self.status_changed.emit("Lade Datei herunter...")
                elif "[Merger] Merging formats into" in line:
                    dest_file_candidate = line.split("into", 1)[1].strip().strip('"')
                    self.final_filename = dest_file_candidate
                    self.status_changed.emit("Audio & Video werden mit FFmpeg zusammengeführt...")
                elif "[ExtractAudio] Destination:" in line:
                    dest_file_candidate = line.split("Destination:", 1)[1].strip()
                    self.final_filename = dest_file_candidate
                    self.status_changed.emit("Konvertiere Audio mit FFmpeg...")

                # 1. DOWNLOAD_PROGRESS Template Parsing (Exakte Werte inklusive ETA)
                if "DOWNLOAD_PROGRESS:" in line:
                    try:
                        raw_data = line.split("DOWNLOAD_PROGRESS:", 1)[1].strip()
                        parts = raw_data.split("|")
                        if len(parts) >= 5:
                            pct_raw = parts[0].replace("%", "").strip()
                            try:
                                pct = float(pct_raw)
                            except ValueError:
                                pct = 0.0

                            tot = parts[1].strip()
                            spd = parts[2].strip()
                            eta = parts[3].strip()
                            dl = parts[4].strip()

                            if tot in ["NA", "Unknown"]:
                                tot = ""
                            if spd in ["NA", "Unknown B/s", "Unknown"]:
                                spd = ""
                            if dl in ["NA", "Unknown"]:
                                dl = ""

                            if tot and dl:
                                size_str = f"{dl} von {tot}"
                            elif dl:
                                size_str = dl
                            else:
                                size_str = ""

                            if not self.is_live:
                                self.progress_changed.emit(pct, spd, eta, size_str)
                    except Exception as e:
                        print("Fehler beim Progress-Parsing:", e)

                # 2. Live Stream Updates
                if self.is_live:
                    now = time.time()
                    if now - last_live_update >= 0.8:
                        last_live_update = now
                        elapsed = int(now - self.start_time)
                        m, s = divmod(elapsed, 60)
                        h, m = divmod(m, 60)
                        time_str = f"{h}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"

                        size_str = ""
                        if dest_file_candidate and os.path.exists(dest_file_candidate):
                            sz = os.path.getsize(dest_file_candidate) / (1024 * 1024)
                            size_str = f"{sz:.1f} MB"

                        self.progress_changed.emit(0.0, "", time_str, size_str)
                    continue

                # 3. Fallback Regex Parsing falls Template nicht griff
                if "DOWNLOAD_PROGRESS:" not in line:
                    m_prog = PROGRESS_FALLBACK_REGEX.search(line)
                    if m_prog:
                        pct = float(m_prog.group(1))
                        tot = m_prog.group(2) or ""
                        spd = m_prog.group(3) or ""
                        eta = m_prog.group(4) or ""
                        self.progress_changed.emit(pct, spd, eta, tot)

                # Fehlerzeilen erfassen
                if "ERROR:" in line or "Operation not permitted" in line or "The page needs to be reloaded" in line:
                    captured_error = line

            self._process.wait()
            return_code = self._process.returncode

            if self.is_live and (self._is_stopping_live or self._is_cancelled):
                self.progress_changed.emit(100.0, "", "", "")
                self.status_changed.emit("Live-Aufnahme erfolgreich gespeichert!")
                self.download_finished.emit(self.final_filename or self.output_dir)
                return True

            if self._is_cancelled:
                self.status_changed.emit("Download abgebrochen.")
                self.download_error.emit("Vorgang wurde vom Benutzer abgebrochen.")
                return True

            if return_code == 0:
                self.progress_changed.emit(100.0, "", "", "")
                self.status_changed.emit("Fertiggestellt!")
                self.download_finished.emit(self.final_filename or dest_file_candidate or self.output_dir)
                return True
            else:
                if "Operation not permitted" in captured_error or "cookies" in captured_error.lower():
                    return False
                
                err_msg = captured_error or f"Download-Prozess beendet mit Fehlercode {return_code}"
                self.status_changed.emit("Fehler aufgetreten!")
                self.download_error.emit(err_msg)
                return False

        except Exception as e:
            if not self._is_cancelled:
                self.status_changed.emit("Fehler aufgetreten!")
                self.download_error.emit(str(e))
            return False
