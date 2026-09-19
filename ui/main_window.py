from PySide6.QtWidgets import QMainWindow, QTabWidget, QWidget, QVBoxLayout
from PySide6.QtCore import Qt
from ui.tabs.youtube_tab import YouTubeTab
from ui.tabs.tiktok_tab import TikTokTab
from ui.tabs.instagram_tab import InstagramTab
from ui.tabs.twitch_tab import TwitchTab
from ui.tabs.universal_tab import UniversalTab
from ui.tabs.settings_tab import SettingsTab
from ui.style import MAC_NATIVE_THEME

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("lennartlol Downloader")
        self.resize(840, 680)
        self.setMinimumSize(750, 560)
        self._init_ui()

    def _init_ui(self):
        # macOS natives Styling anwenden
        self.setStyleSheet(MAC_NATIVE_THEME)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(14, 14, 14, 14)
        main_layout.setSpacing(10)

        # Tabs oben im macOS Segmented Look
        self.tabs = QTabWidget()
        self.tabs.setDocumentMode(True)

        # Plattform-Tabs
        self.youtube_tab = YouTubeTab()
        self.tiktok_tab = TikTokTab()
        self.instagram_tab = InstagramTab()
        self.twitch_tab = TwitchTab()
        self.universal_tab = UniversalTab()
        self.settings_tab = SettingsTab()

        self.tabs.addTab(self.youtube_tab, "📺 YouTube")
        self.tabs.addTab(self.tiktok_tab, "🎵 TikTok")
        self.tabs.addTab(self.instagram_tab, "📸 Instagram")
        self.tabs.addTab(self.twitch_tab, "🟣 Twitch")
        self.tabs.addTab(self.universal_tab, "🌐 Universal")
        self.tabs.addTab(self.settings_tab, "⚙️ Einstellungen")

        main_layout.addWidget(self.tabs)
