from PySide6.QtWidgets import QWidget, QLabel, QVBoxLayout, QHBoxLayout, QFrame
from PySide6.QtCore import Qt
from PySide6.QtGui import QPixmap, QImage
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest
from core.inspector import VideoInfo

class VideoCard(QFrame):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("videoCard")
        self.setStyleSheet("""
            QFrame#videoCard {
                background-color: #262629;
                border-radius: 10px;
                border: 1px solid #36363a;
                padding: 10px;
            }
        """)
        self.network_manager = QNetworkAccessManager(self)
        self.network_manager.finished.connect(self._on_thumbnail_downloaded)
        self._init_ui()
        self.hide()

    def _init_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(6, 6, 6, 6)
        layout.setSpacing(14)

        # Thumbnail Label mit abgerundeten Ecken
        self.thumb_label = QLabel()
        self.thumb_label.setFixedSize(160, 90)
        self.thumb_label.setStyleSheet("background-color: #1e1e20; border-radius: 6px;")
        self.thumb_label.setAlignment(Qt.AlignCenter)
        self.thumb_label.setText("Vorschau")
        layout.addWidget(self.thumb_label)

        # Details Layout (Titel, Uploader, Dauer)
        info_layout = QVBoxLayout()
        info_layout.setSpacing(6)

        self.title_label = QLabel("Video-Titel")
        self.title_label.setStyleSheet("font-size: 14px; font-weight: 600; color: #ffffff;")
        self.title_label.setWordWrap(True)
        info_layout.addWidget(self.title_label)

        self.meta_label = QLabel("Kanal • Dauer")
        self.meta_label.setStyleSheet("font-size: 12px; color: #8e8e93;")
        info_layout.addWidget(self.meta_label)

        self.badge_label = QLabel("")
        self.badge_label.setStyleSheet("""
            background-color: #ff453a;
            color: #ffffff;
            font-size: 11px;
            font-weight: bold;
            padding: 3px 8px;
            border-radius: 4px;
        """)
        self.badge_label.hide()
        info_layout.addWidget(self.badge_label, alignment=Qt.AlignLeft)

        info_layout.addStretch()
        layout.addLayout(info_layout)

    def set_video_info(self, info: VideoInfo):
        self.title_label.setText(info.title)
        
        meta_text = f"👤 {info.uploader}   •   ⏱️ {info.duration_str}"
        if info.extractor:
            meta_text += f"   •   🌐 {info.extractor}"
        self.meta_label.setText(meta_text)

        if info.is_live:
            self.badge_label.setText("🔴 LIVE STREAM")
            self.badge_label.show()
        else:
            self.badge_label.hide()

        # Thumbnail laden
        if info.thumbnail:
            self.thumb_label.setText("Lade...")
            req = QNetworkRequest(info.thumbnail)
            self.network_manager.get(req)
        else:
            self.thumb_label.setText("Kein Bild")

        self.show()

    def _on_thumbnail_downloaded(self, reply):
        if reply.error() == reply.NetworkError.NoError:
            data = reply.readAll()
            img = QImage()
            if img.loadFromData(data):
                pixmap = QPixmap.fromImage(img)
                scaled = pixmap.scaled(self.thumb_label.size(), Qt.KeepAspectRatioByExpanding, Qt.SmoothTransformation)
                self.thumb_label.setPixmap(scaled)
            else:
                self.thumb_label.setText("Vorschau")
        else:
            self.thumb_label.setText("Vorschau")
        reply.deleteLater()

    def reset(self):
        self.thumb_label.clear()
        self.thumb_label.setText("Vorschau")
        self.title_label.setText("")
        self.meta_label.setText("")
        self.badge_label.hide()
        self.hide()
