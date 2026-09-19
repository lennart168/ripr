import sys
import os

# Verzeichnis zum Python-Pfad hinzufügen
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PySide6.QtWidgets import QApplication
from PySide6.QtCore import Qt
from ui.main_window import MainWindow

def main():
    # Optimierung für macOS Retina Displays
    app = QApplication(sys.argv)
    app.setApplicationName("lennartlol Downloader")
    app.setOrganizationName("lennartlol")

    window = MainWindow()
    window.show()

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
