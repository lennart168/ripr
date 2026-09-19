from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLineEdit, QPushButton, 
    QLabel, QScrollArea, QMessageBox, QApplication
)
from PySide6.QtCore import Qt, QThread, Signal
from ui.components.video_card import VideoCard
from ui.components.format_selector import FormatSelector
from ui.components.progress_bar import DownloadProgressBar
from core.inspector import VideoInspector, VideoInfo
from core.engine import DownloadWorker

class InspectorThread(QThread):
    finished_success = Signal(object)
    finished_error = Signal(str)

    def __init__(self, url: str, platform_name: str):
        super().__init__()
        self.url = url
        self.platform_name = platform_name

    def run(self):
        try:
            info = VideoInspector.inspect(self.url, platform_name=self.platform_name)
            self.finished_success.emit(info)
        except Exception as e:
            self.finished_error.emit(str(e))

class BasePlatformTab(QWidget):
    def __init__(self, platform_name: str, placeholder: str, parent=None):
        super().__init__(parent)
        self.platform_name = platform_name
        self.placeholder = placeholder
        self.current_worker: DownloadWorker = None
        self.current_inspector: InspectorThread = None
        self._init_ui()

    def _init_ui(self):
        self.scroll = QScrollArea(self)
        self.scroll.setWidgetResizable(True)
        
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(20, 16, 20, 20)
        layout.setSpacing(14)

        # URL Eingabezeile im macOS Stil
        input_box = QHBoxLayout()
        input_box.setSpacing(8)

        self.url_input = QLineEdit()
        self.url_input.setPlaceholderText(self.placeholder)
        self.url_input.setFixedHeight(34)
        self.url_input.returnPressed.connect(self._start_inspect)
        input_box.addWidget(self.url_input)

        self.btn_paste = QPushButton("📋 Einfügen")
        self.btn_paste.setObjectName("secondaryBtn")
        self.btn_paste.setFixedHeight(34)
        self.btn_paste.clicked.connect(self._paste_clipboard)
        input_box.addWidget(self.btn_paste)

        self.btn_inspect = QPushButton("🔍 Analysieren")
        self.btn_inspect.setFixedHeight(34)
        self.btn_inspect.clicked.connect(self._start_inspect)
        input_box.addWidget(self.btn_inspect)

        layout.addLayout(input_box)

        # Video Vorschau-Karte
        self.video_card = VideoCard(self)
        layout.addWidget(self.video_card)

        # Format- und Codec-Wähler
        self.format_selector = FormatSelector(self)
        layout.addWidget(self.format_selector)

        # Download Start Button
        self.btn_download = QPushButton("⬇️ Download starten")
        self.btn_download.setObjectName("primaryDownloadBtn")
        self.btn_download.setFixedHeight(40)
        self.btn_download.clicked.connect(self._start_download)
        self.btn_download.hide()
        layout.addWidget(self.btn_download)

        # Ladebalken & Statusanzeige
        self.progress_bar = DownloadProgressBar(self)
        self.progress_bar.cancel_clicked.connect(self._cancel_download)
        layout.addWidget(self.progress_bar)

        layout.addStretch()
        self.scroll.setWidget(container)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(self.scroll)

    def _paste_clipboard(self):
        clipboard = QApplication.clipboard()
        text = clipboard.text().strip()
        if text:
            self.url_input.setText(text)
            self._start_inspect()

    def _start_inspect(self):
        url = self.url_input.text().strip()
        if not url:
            QMessageBox.warning(self, "Fehlende URL", "Bitte gib eine Video- oder Stream-URL ein.")
            return

        self.btn_inspect.setEnabled(False)
        self.video_card.reset()
        self.format_selector.reset()
        self.btn_download.hide()
        
        # Zeige Ladebalken während der Analyse
        self.progress_bar.start_analyzing()

        self.current_inspector = InspectorThread(url, self.platform_name)
        self.current_inspector.finished_success.connect(self._on_inspect_success)
        self.current_inspector.finished_error.connect(self._on_inspect_error)
        self.current_inspector.start()

    def _on_inspect_success(self, info: VideoInfo):
        self.btn_inspect.setEnabled(True)
        self.progress_bar.hide()

        self.video_card.set_video_info(info)
        self.format_selector.populate(info)
        
        if info.is_live:
            self.btn_download.setText("🔴 Live-Aufnahme starten")
        else:
            self.btn_download.setText("⬇️ Jetzt herunterladen")

        self.btn_download.show()

    def _on_inspect_error(self, err_msg: str):
        self.btn_inspect.setEnabled(True)
        self.progress_bar.set_error("Konnte Video nicht laden.")
        QMessageBox.critical(
            self, 
            "Fehler beim Analysieren", 
            f"Konnte Stream-Informationen nicht abrufen:\n\n{err_msg}\n\n"
            f"Tipp: In den Einstellungen kannst du Cookies für die gewünschte Plattform aktivieren."
        )

    def _start_download(self):
        url = self.url_input.text().strip()
        options = self.format_selector.get_selected_options()

        self.btn_download.setEnabled(False)
        self.btn_inspect.setEnabled(False)
        
        # Ladebalken mit verbleibender Zeit starten
        self.progress_bar.start_download(is_live=options.get("is_live", False))
        self.scroll.ensureWidgetVisible(self.progress_bar)

        self.current_worker = DownloadWorker(
            url=url,
            output_dir=options["output_dir"],
            platform_name=self.platform_name,
            mode=options["mode"],
            video_selector=options["video_selector"],
            audio_format=options["audio_format"],
            audio_quality=options["audio_quality"],
            is_live=options.get("is_live", False)
        )

        self.current_worker.progress_changed.connect(self.progress_bar.update_progress)
        self.current_worker.status_changed.connect(self.progress_bar.update_status)
        self.current_worker.download_finished.connect(self._on_download_finished)
        self.current_worker.download_error.connect(self._on_download_error)
        self.current_worker.start()

    def _cancel_download(self):
        if self.current_worker and self.current_worker.isRunning():
            self.current_worker.cancel()

    def _on_download_finished(self, filepath: str):
        self.btn_download.setEnabled(True)
        self.btn_inspect.setEnabled(True)
        self.progress_bar.set_finished(filepath)
        self.scroll.ensureWidgetVisible(self.progress_bar)

    def _on_download_error(self, err_msg: str):
        self.btn_download.setEnabled(True)
        self.btn_inspect.setEnabled(True)
        self.progress_bar.set_error(err_msg)
        self.scroll.ensureWidgetVisible(self.progress_bar)
