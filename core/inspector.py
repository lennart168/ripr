import os
import re
from typing import Dict, List, Any, Optional
import yt_dlp
from .config import config

def format_duration(seconds: Optional[int]) -> str:
    if not seconds:
        return "Unbekannt"
    m, s = divmod(int(seconds), 60)
    h, m = divmod(m, 60)
    if h > 0:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"

def clean_codec_name(vcodec: str) -> str:
    if not vcodec or vcodec == "none":
        return "Kein Video"
    vcodec_lower = vcodec.lower()
    if vcodec_lower.startswith("avc1") or "h264" in vcodec_lower:
        return "H.264 (AVC) - Höchste Kompatibilität"
    elif vcodec_lower.startswith("vp9") or vcodec_lower.startswith("vp09"):
        return "VP9"
    elif vcodec_lower.startswith("av01") or "av1" in vcodec_lower:
        return "AV1"
    elif vcodec_lower.startswith("hev1") or vcodec_lower.startswith("hvc1") or "h265" in vcodec_lower:
        return "H.265 (HEVC)"
    return vcodec.split(".")[0]

class VideoInfo:
    def __init__(self, raw_data: Dict[str, Any]):
        self.raw = raw_data
        self.id = raw_data.get("id", "")
        self.title = raw_data.get("title", "Unbekannter Titel")
        self.thumbnail = raw_data.get("thumbnail", "")
        self.duration = raw_data.get("duration", 0)
        self.duration_str = format_duration(self.duration)
        self.uploader = raw_data.get("uploader") or raw_data.get("channel") or raw_data.get("creator") or "Unbekannter Autor"
        self.extractor = raw_data.get("extractor_key", "")
        self.is_live = bool(raw_data.get("is_live") or raw_data.get("live_status") == "is_live")
        self.formats = raw_data.get("formats", [])
        
        self.video_options: List[Dict[str, Any]] = []
        self.audio_options: List[Dict[str, Any]] = []
        self._parse_formats()

    def _parse_formats(self):
        # 1. Standard Audio Options
        self.audio_options = [
            {"label": "MP3 (320 kbps - Höchste Qualität)", "format": "mp3", "quality": "0"},
            {"label": "M4A / AAC (Beste Apple/Mac-Kompatibilität)", "format": "m4a", "quality": "0"},
            {"label": "FLAC (Verlustfrei / Lossless)", "format": "flac", "quality": "0"},
            {"label": "WAV (Unkomprimiert)", "format": "wav", "quality": "0"},
            {"label": "OPUS (Original Web-Audio)", "format": "opus", "quality": "0"}
        ]

        if self.is_live:
            # Bei Live-Streams (z.B. Twitch) sind die Formate oft m3u8-Streams
            for f in self.formats:
                height = f.get("height") or 0
                fps = f.get("fps") or 0
                format_id = f.get("format_id", "")
                note = f.get("format_note", "")

                label = f"{height}p" if height else format_id
                if fps and fps > 30:
                    label += f"{int(fps)}"
                if note:
                    label += f" ({note})"

                self.video_options.append({
                    "height": height,
                    "fps": fps,
                    "res_label": label,
                    "codec_label": "Live HLS Stream",
                    "display": f"🔴 {label}",
                    "selector": format_id or "best",
                    "format_id": format_id,
                    "ext": "mp4"
                })

            # Sortieren nach Höhe
            self.video_options.sort(key=lambda x: x["height"], reverse=True)
            self.video_options.insert(0, {
                "height": 99999,
                "fps": 60,
                "res_label": "Beste Live-Qualität",
                "codec_label": "Automatisch",
                "display": "⭐️ Beste Live-Qualität (Quelle / Source)",
                "selector": "best",
                "format_id": "best",
                "ext": "mp4"
            })
            return

        # 2. Reguläre Video Formate
        seen_combos = set()
        for f in self.formats:
            vcodec = f.get("vcodec", "none")
            if vcodec == "none":
                continue
            
            height = f.get("height")
            if not height:
                continue

            fps = f.get("fps") or 30
            fps_str = f" {int(fps)}fps" if fps and fps > 30 else ""
            codec_label = clean_codec_name(vcodec)
            format_id = f.get("format_id")
            ext = f.get("ext", "mp4")

            res_label = f"{height}p"
            if height >= 2160:
                res_label += " (4K UHD)"
            elif height >= 1440:
                res_label += " (2K QHD)"
            elif height >= 1080:
                res_label += " (Full HD)"
            elif height >= 720:
                res_label += " (HD)"

            combo_key = (height, codec_label)
            if combo_key not in seen_combos:
                seen_combos.add(combo_key)
                
                vcodec_filter = ""
                if "H.264" in codec_label:
                    vcodec_filter = "[vcodec^=avc1]"
                elif "VP9" in codec_label:
                    vcodec_filter = "[vcodec^=vp09]"
                elif "AV1" in codec_label:
                    vcodec_filter = "[vcodec^=av01]"

                selector = f"bestvideo[height<={height}]{vcodec_filter}+bestaudio/best[height<={height}]/best"

                self.video_options.append({
                    "height": height,
                    "fps": fps,
                    "res_label": res_label + fps_str,
                    "codec_label": codec_label,
                    "display": f"{res_label}{fps_str} — {codec_label}",
                    "selector": selector,
                    "format_id": format_id,
                    "ext": ext
                })

        self.video_options.sort(key=lambda x: (x["height"], "H.264" in x["codec_label"]), reverse=True)

        self.video_options.insert(0, {
            "height": 99999,
            "fps": 60,
            "res_label": "Beste verfügbare Qualität",
            "codec_label": "Automatisch (Bestes Video + Bester Ton)",
            "display": "⭐️ Beste verfügbare Qualität (Automatisch)",
            "selector": "bestvideo+bestaudio/best",
            "format_id": "best",
            "ext": "mp4"
        })

class VideoInspector:
    @staticmethod
    def _build_ydl_opts(url: str, platform_name: str, use_cookies: bool = True) -> Dict[str, Any]:
        opts: Dict[str, Any] = {
            "quiet": True,
            "no_warnings": True,
            "skip_download": True,
            "noplaylist": True,
            "remote_components": ["ejs:github"],
        }

        if use_cookies:
            browser, cookie_file = config.get_cookie_settings_for_platform(platform_name)
            if browser and browser != "none":
                if browser == "custom_file" and cookie_file and os.path.exists(cookie_file):
                    opts["cookiefile"] = cookie_file
                elif browser in ["safari", "chrome", "firefox", "brave", "edge"]:
                    opts["cookiesfrombrowser"] = (browser,)

        return opts

    @classmethod
    def inspect(cls, url: str, platform_name: str = "Universal") -> VideoInfo:
        """
        Analysiert die URL. Falls ein Cookie-Fehler (z.B. Safari Berechtigung oder YouTube Reload)
        auftritt, wird automatisch ein robuster Fallback ohne Cookies ausgeführt.
        """
        # 1. Versuch mit plattform-spezifischen Cookies
        try:
            opts = cls._build_ydl_opts(url, platform_name, use_cookies=True)
            with yt_dlp.YoutubeDL(opts) as ydl:
                info = ydl.extract_info(url, download=False)
                if info:
                    return VideoInfo(info)
        except Exception as e:
            err_str = str(e)
            is_cookie_or_reload_err = any(k in err_str.lower() for k in [
                "operation not permitted", 
                "cookies", 
                "the page needs to be reloaded",
                "could not find",
                "sign in to confirm"
            ])
            
            if not is_cookie_or_reload_err:
                # Kein Cookie-Fehler, werfe Fehler weiter
                raise e

            print(f"Cookie-Hinweis: Fehler bei Cookie-Verwendung ({err_str}). Wiederhole ohne Cookies...")

        # 2. Automatischer Fallback: Ohne Cookies versuchen
        opts_fallback = cls._build_ydl_opts(url, platform_name, use_cookies=False)
        with yt_dlp.YoutubeDL(opts_fallback) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise ValueError("Konnte keine Video-Informationen abrufen.")
            return VideoInfo(info)
