import unittest
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from PySide6.QtWidgets import QApplication
from ui.main_window import MainWindow
from ui.components.progress_bar import DownloadProgressBar, format_eta_friendly

class TestUI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ["QT_QPA_PLATFORM"] = "offscreen"
        cls.app = QApplication.instance() or QApplication([])

    def test_main_window_creation(self):
        window = MainWindow()
        self.assertIsNotNone(window)
        self.assertEqual(window.tabs.count(), 6)
        
        tab_names = [window.tabs.tabText(i) for i in range(window.tabs.count())]
        self.assertIn("📺 YouTube", tab_names)
        self.assertIn("🎵 TikTok", tab_names)
        self.assertIn("📸 Instagram", tab_names)
        self.assertIn("🟣 Twitch", tab_names)
        self.assertIn("🌐 Universal", tab_names)
        self.assertIn("⚙️ Einstellungen", tab_names)

    def test_eta_formatting(self):
        self.assertEqual(format_eta_friendly("00:15"), "Noch ca. 15 Sekunden")
        self.assertEqual(format_eta_friendly("01:25"), "Noch ca. 1 Min 25 Sek")
        self.assertEqual(format_eta_friendly("05:00"), "Noch ca. 5 Min 00 Sek")
        self.assertEqual(format_eta_friendly("01:10:00"), "Noch ca. 1 Std 10 Min")
        self.assertEqual(format_eta_friendly("Unknown"), "Berechne Restzeit...")

    def test_progress_bar_updates(self):
        bar = DownloadProgressBar()
        bar.start_download(is_live=False)
        self.assertTrue(bar.isVisible())
        
        # Test Progress Update
        bar.update_progress(45.2, "4.5 MB/s", "00:20", "15 MB von 33 MB")
        self.assertIn("45.2%", bar.status_label.text())
        self.assertIn("20 Sekunden", bar.eta_label.text())
        self.assertIn("4.5 MB/s", bar.details_label.text())

if __name__ == "__main__":
    unittest.main()
