import subprocess
import os
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QProgressBar, QLabel, 
    QPushButton, QFrame
)
from PySide6.QtCore import Qt, Signal

def format_eta_friendly(eta_str: str) -> str:
    """Wandelt einen ETA-String (z.B. 00:15 oder 01:25) in lesbare deutsche Zeitangabe um."""
    if not eta_str or eta_str in ["Unknown", "NA", "--:--"]:
        return "Berechne Restzeit..."
    
    parts = eta_str.strip().split(":")
    try:
        if len(parts) == 2:
            m = int(parts[0])
            s = int(parts[1])
            if m == 0:
                return f"Noch ca. {s} Sekunden"
            elif m == 1:
                return f"Noch ca. 1 Min {s} Sek"
            else:
                return f"Noch ca. {m} Min {s:02d} Sek"
        elif len(parts) == 3:
            h = int(parts[0])
            m = int(parts[1])
            return f"Noch ca. {h} Std {m} Min"
    except Exception:
        pass
    return f"Noch ca. {eta_str}"

class DownloadProgressBar(QFrame):
    cancel_clicked = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("progressCard")
        self.setStyleSheet("""
            QFrame#progressCard {
                background-color: #262629;
                border-radius: 10px;
                border: 1px solid #3a3a3e;
                padding: 14px;
            }
        """)
        self.output_filepath = ""
        self.is_live = False
        self._init_ui()
        self.hide()

    def _init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(10)

        # 1. Obere Zeile: Status-Titel & Aktions-Button
        top_row = QHBoxLayout()
        self.status_label = QLabel("Bereit")
        self.status_label.setStyleSheet("font-weight: 700; color: #ffffff; font-size: 14px;")
        top_row.addWidget(self.status_label)
        top_row.addStretch()

        self.btn_cancel = QPushButton("Abbrechen")
        self.btn_cancel.setObjectName("cancelBtn")
        self.btn_cancel.setFixedHeight(30)
        self.btn_cancel.clicked.connect(self.cancel_clicked.emit)
        top_row.addWidget(self.btn_cancel)

        layout.addLayout(top_row)

        # 2. Prominenter Ladebalken
        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        self.progress_bar.setFixedHeight(12)
        self.progress_bar.setTextVisible(False)
        self.progress_bar.setStyleSheet("""
            QProgressBar {
                background-color: #1e1e20;
                border-radius: 6px;
                border: 1px solid #38383c;
            }
            QProgressBar::chunk {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #007aff, stop:1 #34c759);
                border-radius: 5px;
            }
        """)
        layout.addWidget(self.progress_bar)

        # 3. Informationsbereich (Restzeit, Download-Größe & Geschwindigkeit)
        info_layout = QVBoxLayout()
        info_layout.setSpacing(4)

        # Zeile für verbleibende Zeit (hervorgehoben)
        self.eta_label = QLabel("⏱️ Verbleibende Zeit: Berechne...")
        self.eta_label.setStyleSheet("font-size: 13px; font-weight: 600; color: #30d158;")
        info_layout.addWidget(self.eta_label)

        # Zeile für Größe und Geschwindigkeit
        self.details_label = QLabel("")
        self.details_label.setStyleSheet("font-size: 12px; color: #98989f;")
        info_layout.addWidget(self.details_label)

        layout.addLayout(info_layout)

        # 4. Button nach Fertigstellung
        self.btn_reveal = QPushButton("📂 Heruntergeladene Datei im Finder anzeigen")
        self.btn_reveal.setObjectName("secondaryBtn")
        self.btn_reveal.setFixedHeight(32)
        self.btn_reveal.setStyleSheet("""
            QPushButton {
                background-color: #323236;
                color: #30d158;
                font-weight: 600;
                border: 1px solid #444448;
                border-radius: 7px;
            }
            QPushButton:hover {
                background-color: #3c3c40;
                color: #34c759;
            }
        """)
        self.btn_reveal.clicked.connect(self._reveal_in_finder)
        self.btn_reveal.hide()
        layout.addWidget(self.btn_reveal)

    def start_analyzing(self):
        """Wird aufgerufen, wenn der Link analysiert wird."""
        self.is_live = False
        self.progress_bar.setRange(0, 0)  # Pulsiert hin und her
        self.status_label.setText("🔍 Video-Informationen & Qualitätsstufen werden geladen...")
        self.eta_label.setText("⏱️ Bitte einen kurzen Moment warten...")
        self.details_label.setText("Verbindung zur Plattform wird aufgebaut...")
        self.btn_cancel.hide()
        self.btn_reveal.hide()
        self.output_filepath = ""
        self.show()

    def start_download(self, is_live=False):
        self.is_live = is_live
        self.output_filepath = ""
        self.btn_reveal.hide()
        self.btn_cancel.show()

        if is_live:
            self.progress_bar.setRange(0, 0)  # Indeterminate Mode
            self.status_label.setText("🔴 Live-Aufnahme läuft...")
            self.eta_label.setText("⏱️ Aufnahmedauer: 00:00")
            self.details_label.setText("Empfange Live-Stream...")
            self.btn_cancel.setText("⏹️ Aufnahme beenden & Speichern")
        else:
            self.progress_bar.setRange(0, 100)
            self.progress_bar.setValue(0)
            self.status_label.setText("⬇️ Download wird gestartet (0%)...")
            self.eta_label.setText("⏱️ Verbleibende Zeit: Berechne...")
            self.details_label.setText("Verbindung wird hergestellt...")
            self.btn_cancel.setText("Abbrechen")

        self.show()

    def update_progress(self, percent: float, speed: str, eta: str, size: str):
        if not self.is_live:
            int_pct = int(percent)
            if self.progress_bar.maximum() > 0:
                self.progress_bar.setValue(int_pct)
            self.status_label.setText(f"⬇️ Download läuft ({percent:.1f}% abgeschlossen)")
            
            # Verbleibende Zeit anzeigen
            friendly_eta = format_eta_friendly(eta)
            self.eta_label.setText(f"⏱️ Verbleibende Zeit: {friendly_eta}")

            # Details (Größe und Geschwindigkeit)
            parts = []
            if size:
                parts.append(f"💾 {size}")
            if speed:
                parts.append(f"⚡ Geschwindigkeit: {speed}")
            self.details_label.setText("   •   ".join(parts))
        else:
            # Live Stream Updates
            self.status_label.setText("🔴 Live-Stream wird aufgenommen...")
            self.eta_label.setText(f"⏱️ Laufende Aufnahmedauer: {eta}")
            parts = []
            if size:
                parts.append(f"💾 Gespeichert: {size}")
            if speed:
                parts.append(f"⚡ Datenrate: {speed}")
            self.details_label.setText("   •   ".join(parts))

    def update_status(self, status: str):
        self.status_label.setText(status)
        if "FFmpeg" in status:
            self.progress_bar.setRange(0, 0)
            self.eta_label.setText("⏱️ Fast fertig...")
            self.details_label.setText("Audio- und Videospuren werden zusammengefügt...")

    def set_finished(self, filepath: str):
        self.output_filepath = filepath
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(100)
        self.btn_cancel.hide()

        if self.is_live:
            self.status_label.setText("✅ Live-Aufnahme erfolgreich gesichert!")
            self.eta_label.setText("⏱️ Aufnahme abgeschlossen")
        else:
            self.status_label.setText("✅ Download erfolgreich abgeschlossen! (100%)")
            self.eta_label.setText("⏱️ Fertiggestellt!")

        filename = os.path.basename(filepath) if filepath else "Datei"
        self.details_label.setText(f"Gespeichert als: {filename}")

        if filepath and (os.path.exists(filepath) or os.path.exists(os.path.dirname(filepath))):
            self.btn_reveal.show()

    def set_error(self, err_msg: str):
        self.progress_bar.setRange(0, 100)
        self.status_label.setText("❌ Vorgang fehlgeschlagen")
        self.eta_label.setText("⏱️ Abgebrochen")
        self.details_label.setText(err_msg)
        self.btn_cancel.hide()
        self.btn_reveal.hide()

    def _reveal_in_finder(self):
        if self.output_filepath and os.path.exists(self.output_filepath):
            subprocess.run(["open", "-R", self.output_filepath])
        elif self.output_filepath:
            folder = os.path.dirname(self.output_filepath) if os.path.isfile(self.output_filepath) else self.output_filepath
            if os.path.exists(folder):
                subprocess.run(["open", folder])

    def reset(self):
        self.progress_bar.setRange(0, 100)
        self.progress_bar.setValue(0)
        self.status_label.setText("Bereit")
        self.eta_label.setText("")
        self.details_label.setText("")
        self.btn_cancel.hide()
        self.btn_reveal.hide()
        self.hide()
