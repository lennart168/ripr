import json
import os
from pathlib import Path
from typing import Tuple, Optional

DEFAULT_DOWNLOAD_DIR = str(Path.home() / "Downloads")
APP_SUPPORT_DIR = Path.home() / "Library" / "Application Support" / "lennartlol-downloader"
CONFIG_FILE = APP_SUPPORT_DIR / "config.json"

DEFAULT_CONFIG = {
    "download_dir": DEFAULT_DOWNLOAD_DIR,
    "default_mode": "video",          # "video" or "audio"
    "default_audio_format": "mp3",    # "mp3", "m4a", "flac", "wav", "opus"
    "cookie_browser": "none",         # "none", "safari", "chrome", "firefox", "brave", "edge", "custom_file"
    "cookie_file_path": "",
    "use_cookies_instagram": True,    # Instagram profitiert stark von Cookies
    "use_cookies_youtube": False,     # YouTube blockiert oft bei Browser-Cookies ("page needs to be reloaded")
    "use_cookies_twitch": False,
    "use_cookies_universal": False,
    "embed_thumbnail": True,
    "embed_metadata": True,
    "theme": "native",                # "native", "dark", "light"
    "auto_check_updates": True
}

class ConfigManager:
    def __init__(self):
        self._ensure_dir()
        self.data = self._load()

    def _ensure_dir(self):
        try:
            APP_SUPPORT_DIR.mkdir(parents=True, exist_ok=True)
        except Exception:
            pass

    def _load(self) -> dict:
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    loaded = json.load(f)
                    cfg = DEFAULT_CONFIG.copy()
                    cfg.update(loaded)
                    return cfg
            except Exception:
                pass
        return DEFAULT_CONFIG.copy()

    def save(self):
        try:
            self._ensure_dir()
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(self.data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error saving config: {e}")

    def get(self, key, default=None):
        return self.data.get(key, default)

    def set(self, key, value):
        self.data[key] = value
        self.save()

    def get_cookie_settings_for_platform(self, platform_name: str) -> Tuple[Optional[str], Optional[str]]:
        """
        Ermittelt, ob für die jeweilige Plattform Cookies verwendet werden sollen.
        Gibt (browser_name, cookie_file) zurück.
        """
        browser = self.get("cookie_browser", "none")
        cookie_file = self.get("cookie_file_path", "")

        if browser == "none" and not cookie_file:
            return None, None

        platform_lower = platform_name.lower()
        should_use = False

        if "instagram" in platform_lower:
            should_use = self.get("use_cookies_instagram", True)
        elif "youtube" in platform_lower:
            should_use = self.get("use_cookies_youtube", False)
        elif "twitch" in platform_lower:
            should_use = self.get("use_cookies_twitch", False)
        else:
            should_use = self.get("use_cookies_universal", False)

        if not should_use:
            return None, None

        return browser, cookie_file

# Global config singleton
config = ConfigManager()
