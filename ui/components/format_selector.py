import os
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QRadioButton, 
    QButtonGroup, QComboBox, QLabel, QLineEdit, QPushButton, 
    QFileDialog, QGroupBox
)
from PySide6.QtCore import Qt, Signal
from core.config import config
from core.inspector import VideoInfo

class FormatSelector(QWidget):
    options_changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.current_video_info: VideoInfo = None
        self._init_ui()
        self.hide()

    def _init_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(14)

        # Modus-Auswahl (Video vs. Audio)
        mode_group_box = QGroupBox("1. Download-Typ auswählen")
        mode_layout = QHBoxLayout(mode_group_box)
        mode_layout.setSpacing(24)

        self.btn_group = QButtonGroup(self)
        self.radio_video = QRadioButton("🎬 Video herunterladen")
        self.radio_audio = QRadioButton("🎧 Nur Audio extrahieren (Musik/Podcast)")

        default_mode = config.get("default_mode", "video")
        if default_mode == "audio":
            self.radio_audio.setChecked(True)
        else:
            self.radio_video.setChecked(True)

        self.btn_group.addButton(self.radio_video)
        self.btn_group.addButton(self.radio_audio)
        mode_layout.addWidget(self.radio_video)
        mode_layout.addWidget(self.radio_audio)
        mode_layout.addStretch()

        self.radio_video.toggled.connect(self._on_mode_toggled)
        main_layout.addWidget(mode_group_box)

        # Format & Qualitäts-Auswahl Box
        self.quality_group_box = QGroupBox("2. Qualität & Codec festlegen")
        quality_layout = QVBoxLayout(self.quality_group_box)
        quality_layout.setSpacing(10)

        # Video Qualitäts-Zeile
        self.video_row = QWidget()
        v_layout = QHBoxLayout(self.video_row)
        v_layout.setContentsMargins(0, 0, 0, 0)
        v_label = QLabel("Auflösung & Codec:")
        v_label.setFixedWidth(130)
        self.combo_video = QComboBox()
        self.combo_video.currentIndexChanged.connect(self.options_changed.emit)
        v_layout.addWidget(v_label)
        v_layout.addWidget(self.combo_video)
        quality_layout.addWidget(self.video_row)

        # Audio Qualitäts-Zeile
        self.audio_row = QWidget()
        a_layout = QHBoxLayout(self.audio_row)
        a_layout.setContentsMargins(0, 0, 0, 0)
        a_label = QLabel("Audio-Format:")
        a_label.setFixedWidth(130)
        self.combo_audio = QComboBox()
        self.combo_audio.currentIndexChanged.connect(self.options_changed.emit)
        a_layout.addWidget(a_label)
        a_layout.addWidget(self.combo_audio)
        quality_layout.addWidget(self.audio_row)

        main_layout.addWidget(self.quality_group_box)

        # Speicherort Box
        path_group_box = QGroupBox("3. Zielordner auswählen")
        path_layout = QHBoxLayout(path_group_box)
        path_layout.setSpacing(10)

        self.path_edit = QLineEdit()
        self.path_edit.setText(config.get("download_dir", os.path.expanduser("~/Downloads")))
        self.path_edit.setReadOnly(True)

        self.btn_browse = QPushButton("Ordner wählen...")
        self.btn_browse.setObjectName("secondaryBtn")
        self.btn_browse.clicked.connect(self._browse_folder)

        path_layout.addWidget(self.path_edit)
        path_layout.addWidget(self.btn_browse)

        main_layout.addWidget(path_group_box)

        self._update_visibility()

    def _on_mode_toggled(self):
        self._update_visibility()
        self.options_changed.emit()

    def _update_visibility(self):
        is_video = self.radio_video.isChecked()
        self.video_row.setVisible(is_video)
        self.audio_row.setVisible(not is_video)

    def _browse_folder(self):
        chosen_dir = QFileDialog.getExistingDirectory(
            self,
            "Download-Zielordner auswählen",
            self.path_edit.text() or os.path.expanduser("~/Downloads")
        )
        if chosen_dir:
            self.path_edit.setText(chosen_dir)

    def populate(self, info: VideoInfo):
        self.current_video_info = info
        self.combo_video.clear()
        self.combo_audio.clear()

        # Video-Optionen füllen
        for opt in info.video_options:
            self.combo_video.addItem(opt["display"], opt["selector"])

        # Audio-Optionen füllen
        default_fmt = config.get("default_audio_format", "mp3")
        default_index = 0
        for i, opt in enumerate(info.audio_options):
            self.combo_audio.addItem(opt["label"], opt)
            if opt["format"] == default_fmt:
                default_index = i
        self.combo_audio.setCurrentIndex(default_index)

        self.show()

    def get_selected_options(self) -> dict:
        is_video = self.radio_video.isChecked()
        mode = "video" if is_video else "audio"

        video_selector = self.combo_video.currentData() or "bestvideo+bestaudio/best"
        
        audio_data = self.combo_audio.currentData() or {"format": "mp3", "quality": "0"}
        audio_format = audio_data.get("format", "mp3")
        audio_quality = audio_data.get("quality", "0")

        output_dir = self.path_edit.text().strip() or os.path.expanduser("~/Downloads")

        return {
            "mode": mode,
            "video_selector": video_selector,
            "audio_format": audio_format,
            "audio_quality": audio_quality,
            "output_dir": output_dir,
            "is_live": self.current_video_info.is_live if self.current_video_info else False
        }

    def reset(self):
        self.current_video_info = None
        self.combo_video.clear()
        self.combo_audio.clear()
        self.hide()
