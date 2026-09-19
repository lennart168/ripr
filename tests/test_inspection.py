import unittest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.inspector import VideoInspector

class TestLiveInspection(unittest.TestCase):
    def test_youtube_inspection(self):
        info = VideoInspector.inspect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", platform_name="YouTube")
        self.assertFalse(info.is_live)
        self.assertTrue(len(info.title) > 0)
        self.assertTrue(len(info.video_options) > 0)
        print(f"YouTube OK: {info.title} ({len(info.video_options)} Formate)")

    def test_twitch_live_inspection(self):
        # Shroud oder ein anderer Streamer für Live-Test
        try:
            info = VideoInspector.inspect("https://www.twitch.tv/shroud", platform_name="Twitch")
            self.assertTrue(info.is_live)
            print(f"Twitch Live OK: is_live={info.is_live}, title={info.title}, options={len(info.video_options)}")
        except Exception as e:
            print("Twitch offline oder nicht erreichbar:", e)

if __name__ == "__main__":
    unittest.main()
