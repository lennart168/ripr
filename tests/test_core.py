import unittest
import os
import sys

# Projektpfad einbinden
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.config import config, DEFAULT_CONFIG
from core.updater import EngineUpdater
from core.inspector import clean_codec_name, format_duration, VideoInfo

class TestCoreModules(unittest.TestCase):
    def test_config(self):
        self.assertIsNotNone(config.get("download_dir"))
        self.assertEqual(config.get("default_mode"), "video")

    def test_updater_ffmpeg(self):
        ok, msg = EngineUpdater.check_ffmpeg()
        print(f"FFmpeg Check Result: ok={ok}, msg={msg}")
        self.assertTrue(ok, "FFmpeg sollte auf dem Mac gefunden werden")

    def test_updater_ytdlp_version(self):
        ver = EngineUpdater.get_current_ytdlp_version()
        print(f"yt-dlp Version: {ver}")
        self.assertNotEqual(ver, "Unbekannt")

    def test_codec_cleaning(self):
        self.assertIn("H.264", clean_codec_name("avc1.640028"))
        self.assertIn("VP9", clean_codec_name("vp09.00.51.08"))
        self.assertIn("AV1", clean_codec_name("av01.0.08m.08"))

    def test_duration_formatting(self):
        self.assertEqual(format_duration(65), "1:05")
        self.assertEqual(format_duration(3665), "1:01:05")

    def test_video_info_parsing(self):
        # Mock Video Daten
        mock_raw = {
            "id": "test1234",
            "title": "Test Video Title",
            "duration": 120,
            "uploader": "Test Channel",
            "thumbnail": "https://example.com/thumb.jpg",
            "extractor_key": "Youtube",
            "formats": [
                {
                    "format_id": "137",
                    "height": 1080,
                    "fps": 60,
                    "vcodec": "avc1.640028",
                    "ext": "mp4"
                },
                {
                    "format_id": "248",
                    "height": 1080,
                    "fps": 30,
                    "vcodec": "vp09.00.51.08",
                    "ext": "webm"
                },
                {
                    "format_id": "140",
                    "vcodec": "none",
                    "acodec": "mp4a.40.2",
                    "ext": "m4a"
                }
            ]
        }
        info = VideoInfo(mock_raw)
        self.assertEqual(info.title, "Test Video Title")
        self.assertEqual(info.duration_str, "2:00")
        self.assertTrue(len(info.video_options) >= 2)
        self.assertTrue(len(info.audio_options) >= 4)

if __name__ == "__main__":
    unittest.main()
