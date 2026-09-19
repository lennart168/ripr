import os
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, 
    QLineEdit, QFileDialog, QGroupBox, QComboBox, QCheckBox, 
    QScrollArea, QMessageBox
)
from PySide6.QtCore import Qt, QThread, Signal
from core.config import config
from core.updater import EngineUpdater

class UpdateCheckThread(QThread):
    finished_check = Signal(str, str)
    error_check = Signal(str)

    def run(self):
        try:
            ver, url = EngineUpdater.get_latest_ytdlp_version()
            if ver:
                self.finished_check.emit(ver, url)
            else:
                self.error_check.emit("Konnte keine Versionsinformationen von GitHub abrufen.")
        except Exception as e:
            self.error_check.emit(str(e))

class PerformUpdateThread(QThread):
    finished_update = Signal(bool, str)

    def run(self):
        success, msg = EngineUpdater.update_ytdlp()
        self.finished_update.emit(success, msg)

class SettingsTab(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._init_ui()
        self._refresh_status()

    def _init_ui(self):
        scroll = QScrollArea(self)
        scroll.setWidgetResizable(True)

        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(20, 16, 20, 20)
        layout.setSpacing(14)

        # 1. Download-Verzeichnis
        dir_box = QGroupBox("📁 Standard-Speicherort")
        dir_layout = QHBoxLayout(dir_box)
        dir_layout.setContentsMargins(12, 12, 12, 12)
        
        self.edit_dir = QLineEdit(config.get("download_dir", os.path.expanduser("~/Downloads")))
        self.edit_dir.setReadOnly(True)
        dir_layout.addWidget(self.edit_dir)

        self.btn_dir = QPushButton("Ändern...")
        self.btn_dir.setObjectName("secondaryBtn")
        self.btn_dir.clicked.connect(self._change_default_dir)
        dir_layout.addWidget(self.btn_dir)

        layout.addWidget(dir_box)

        # 2. Engine & Updates
        engine_box = QGroupBox("🚀 Download-Engine & Updates")
        engine_layout = QVBoxLayout(engine_box)
        engine_layout.setContentsMargins(12, 12, 12, 12)
        engine_layout.setSpacing(10)

        ver_row = QHBoxLayout()
        self.label_ytdlp_ver = QLabel("yt-dlp Version: Lade...")
        self.label_ytdlp_ver.setStyleSheet("font-size: 13px; color: #ffffff;")
        ver_row.addWidget(self.label_ytdlp_ver)
        ver_row.addStretch()

        self.btn_check_update = QPushButton("Auf Updates prüfen")
        self.btn_check_update.setObjectName("secondaryBtn")
        self.btn_check_update.clicked.connect(self._check_for_updates)
        ver_row.addWidget(self.btn_check_update)

        self.btn_do_update = QPushButton("Jetzt aktualisieren")
        self.btn_do_update.clicked.connect(self._perform_update)
        self.btn_do_update.hide()
        ver_row.addWidget(self.btn_do_update)

        engine_layout.addLayout(ver_row)

        self.label_update_status = QLabel("")
        self.label_update_status.setStyleSheet("color: #30d158; font-size: 12px;")
        self.label_update_status.hide()
        engine_layout.addWidget(self.label_update_status)

        self.label_ffmpeg_status = QLabel("FFmpeg: Lade...")
        self.label_ffmpeg_status.setStyleSheet("color: #8e8e93; font-size: 12px;")
        engine_layout.addWidget(self.label_ffmpeg_status)

        layout.addWidget(engine_box)

        # 3. Cookies & Login-Verwaltung
        cookie_box = QGroupBox("🍪 Browser-Cookies & Plattform-Login")
        cookie_layout = QVBoxLayout(cookie_box)
        cookie_layout.setContentsMargins(12, 12, 12, 12)
        cookie_layout.setSpacing(10)

        cookie_info = QLabel(
            "Wähle deinen Browser, um aktive Logins für geschützte Videos zu verwenden.\n"
            "• Instagram verlangt meist einen Login (empfohlen: aktivieren).\n"
            "• YouTube blockiert oft Anfragen bei aktiven Cookies ('The page needs to be reloaded') und funktioniert ohne Cookies meist am besten."
        )
        cookie_info.setStyleSheet("color: #8e8e93; font-size: 12px; line-height: 1.4;")
        cookie_info.setWordWrap(True)
        cookie_layout.addWidget(cookie_info)

        browser_row = QHBoxLayout()
        browser_row.addWidget(QLabel("Browser für Cookies:"))
        self.combo_browser = QComboBox()
        self.combo_browser.addItem("Keine Cookies (Anonym)", "none")
        self.combo_browser.addItem("Google Chrome", "chrome")
        self.combo_browser.addItem("Mozilla Firefox", "firefox")
        self.combo_browser.addItem("Apple Safari (⚠️ Benötigt Festplattenvollzugriff)", "safari")
        self.combo_browser.addItem("Brave Browser", "brave")
        self.combo_browser.addItem("Eigene cookies.txt Datei", "custom_file")
        
        curr_b = config.get("cookie_browser", "none")
        idx = self.combo_browser.findData(curr_b)
        if idx >= 0:
            self.combo_browser.setCurrentIndex(idx)

        self.combo_browser.currentIndexChanged.connect(self._on_browser_changed)
        browser_row.addWidget(self.combo_browser)
        browser_row.addStretch()
        cookie_layout.addLayout(browser_row)

        # Custom Cookie File
        self.custom_cookie_row = QWidget()
        c_layout = QHBoxLayout(self.custom_cookie_row)
        c_layout.setContentsMargins(0, 0, 0, 0)
        self.edit_cookie_file = QLineEdit(config.get("cookie_file_path", ""))
        self.edit_cookie_file.setPlaceholderText("Pfad zu cookies.txt...")
        self.edit_cookie_file.setReadOnly(True)
        btn_cookie_browse = QPushButton("Datei wählen...")
        btn_cookie_browse.setObjectName("secondaryBtn")
        btn_cookie_browse.clicked.connect(self._browse_cookie_file)
        c_layout.addWidget(self.edit_cookie_file)
        c_layout.addWidget(btn_cookie_browse)
        cookie_layout.addWidget(self.custom_cookie_row)
        self.custom_cookie_row.setVisible(curr_b == "custom_file")

        # Plattform-spezifische Checkboxen
        cookie_targets_label = QLabel("Cookies auf folgenden Plattformen anwenden:")
        cookie_targets_label.setStyleSheet("font-weight: 600; color: #b0b0b8; margin-top: 6px;")
        cookie_layout.addWidget(cookie_targets_label)

        self.check_cookie_ig = QCheckBox("Instagram (Empfohlen für Reels)")
        self.check_cookie_ig.setChecked(config.get("use_cookies_instagram", True))
        self.check_cookie_ig.toggled.connect(lambda v: config.set("use_cookies_instagram", v))
        cookie_layout.addWidget(self.check_cookie_ig)

        self.check_cookie_yt = QCheckBox("YouTube (Standard deaktiviert; nur aktivieren wenn Video altersbeschränkt ist)")
        self.check_cookie_yt.setChecked(config.get("use_cookies_youtube", False))
        self.check_cookie_yt.toggled.connect(lambda v: config.set("use_cookies_youtube", v))
        cookie_layout.addWidget(self.check_cookie_yt)

        self.check_cookie_twitch = QCheckBox("Twitch (Nur bei Abonnenten-Only VODs nötig)")
        self.check_cookie_twitch.setChecked(config.get("use_cookies_twitch", False))
        self.check_cookie_twitch.toggled.connect(lambda v: config.set("use_cookies_twitch", v))
        cookie_layout.addWidget(self.check_cookie_twitch)

        self.check_cookie_universal = QCheckBox("Universal / Andere Seiten")
        self.check_cookie_universal.setChecked(config.get("use_cookies_universal", False))
        self.check_cookie_universal.toggled.connect(lambda v: config.set("use_cookies_universal", v))
        cookie_layout.addWidget(self.check_cookie_universal)

        layout.addWidget(cookie_box)

        # 4. Zusätzliche Optionen
        pref_box = QGroupBox("⚙️ Mediendatei-Optionen")
        pref_layout = QVBoxLayout(pref_box)
        pref_layout.setContentsMargins(12, 12, 12, 12)
        pref_layout.setSpacing(8)

        self.check_thumbnail = QCheckBox("Thumbnail als Cover-Bild in Audio/Video einbetten")
        self.check_thumbnail.setChecked(config.get("embed_thumbnail", True))
        self.check_thumbnail.toggled.connect(lambda v: config.set("embed_thumbnail", v))
        pref_layout.addWidget(self.check_thumbnail)

        self.check_metadata = QCheckBox("Metadaten & Kapitel in Mediendatei einbetten")
        self.check_metadata.setChecked(config.get("embed_metadata", True))
        self.check_metadata.toggled.connect(lambda v: config.set("embed_metadata", v))
        pref_layout.addWidget(self.check_metadata)

        layout.addWidget(pref_box)

        layout.addStretch()
        scroll.setWidget(container)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)

    def _refresh_status(self):
        cur_ver = EngineUpdater.get_current_ytdlp_version()
        self.label_ytdlp_ver.setText(f"yt-dlp Version: <b>{cur_ver}</b>")

        ok, msg = EngineUpdater.check_ffmpeg()
        if ok:
            self.label_ffmpeg_status.setText(f"✅ FFmpeg aktiv: {msg}")
            self.label_ffmpeg_status.setStyleSheet("color: #30d158; font-size: 12px;")
        else:
            self.label_ffmpeg_status.setText(f"⚠️ {msg}")
            self.label_ffmpeg_status.setStyleSheet("color: #ff453a; font-size: 12px;")

    def _change_default_dir(self):
        new_dir = QFileDialog.getExistingDirectory(
            self,
            "Standard-Speicherort wählen",
            self.edit_dir.text()
        )
        if new_dir:
            self.edit_dir.setText(new_dir)
            config.set("download_dir", new_dir)

    def _on_browser_changed(self):
        data = self.combo_browser.currentData()
        config.set("cookie_browser", data)
        self.custom_cookie_row.setVisible(data == "custom_file")

    def _browse_cookie_file(self):
        f, _ = QFileDialog.getOpenFileName(
            self,
            "cookies.txt auswählen",
            os.path.expanduser("~"),
            "Textdateien (*.txt)"
        )
        if f:
            self.edit_cookie_file.setText(f)
            config.set("cookie_file_path", f)

    def _check_for_updates(self):
        self.btn_check_update.setEnabled(False)
        self.label_update_status.setText("Suche nach neuester Version auf GitHub...")
        self.label_update_status.setStyleSheet("color: #8e8e93; font-size: 12px;")
        self.label_update_status.show()

        self.update_thread = UpdateCheckThread()
        self.update_thread.finished_check.connect(self._on_check_finished)
        self.update_thread.error_check.connect(self._on_check_error)
        self.update_thread.start()

    def _on_check_finished(self, latest_ver: str, url: str):
        self.btn_check_update.setEnabled(True)
        cur_ver = EngineUpdater.get_current_ytdlp_version()

        if latest_ver != cur_ver:
            self.label_update_status.setText(f"🎉 Neue Version verfügbar: <b>{latest_ver}</b> (Aktuell: {cur_ver})")
            self.label_update_status.setStyleSheet("color: #ff9f0a; font-size: 12px;")
            self.btn_do_update.setText(f"Auf {latest_ver} aktualisieren")
            self.btn_do_update.show()
        else:
            self.label_update_status.setText(f"✅ Du hast bereits die neueste Version ({cur_ver})!")
            self.label_update_status.setStyleSheet("color: #30d158; font-size: 12px;")
            self.btn_do_update.hide()

    def _on_check_error(self, err_msg: str):
        self.btn_check_update.setEnabled(True)
        self.label_update_status.setText(f"❌ {err_msg}")
        self.label_update_status.setStyleSheet("color: #ff453a; font-size: 12px;")

    def _perform_update(self):
        self.btn_do_update.setEnabled(False)
        self.label_update_status.setText("Aktualisiere yt-dlp... Bitte warten.")
        self.label_update_status.setStyleSheet("color: #007aff; font-size: 12px;")

        self.perform_thread = PerformUpdateThread()
        self.perform_thread.finished_update.connect(self._on_update_completed)
        self.perform_thread.start()

    def _on_update_completed(self, success: bool, msg: str):
        self.btn_do_update.setEnabled(True)
        if success:
            self.label_update_status.setText(f"✅ {msg}")
            self.label_update_status.setStyleSheet("color: #30d158; font-size: 12px;")
            self.btn_do_update.hide()
            self._refresh_status()
            QMessageBox.information(self, "Update erfolgreich", msg)
        else:
            self.label_update_status.setText("❌ Update fehlgeschlagen.")
            self.label_update_status.setStyleSheet("color: #ff453a; font-size: 12px;")
            QMessageBox.critical(self, "Update fehlgeschlagen", msg)
