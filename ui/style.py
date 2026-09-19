# macOS Native Theme (SF Pro, Apple System Colors, Ventura/Sonoma/Sequoia HIG)

MAC_NATIVE_THEME = """
/* Globales macOS Styling */
QWidget {
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Helvetica Neue", Arial, sans-serif;
    font-size: 13px;
    color: #e5e5ea;
    background-color: #1e1e20;
}

/* macOS Fenster-Hintergrund */
QMainWindow {
    background-color: #1c1c1e;
}

/* macOS Segmented Tab Bar */
QTabWidget::pane {
    border: none;
    background-color: transparent;
}

QTabBar {
    background-color: #252528;
    border-radius: 9px;
    padding: 3px;
    qproperty-drawBase: 0;
}

QTabBar::tab {
    background-color: transparent;
    color: #98989f;
    padding: 7px 18px;
    margin: 1px 2px;
    border-radius: 7px;
    font-size: 13px;
    font-weight: 500;
}

QTabBar::tab:selected {
    background-color: #007aff;
    color: #ffffff;
    font-weight: 600;
}

QTabBar::tab:hover:!selected {
    background-color: #323236;
    color: #dedee3;
}

/* macOS Text Input Field */
QLineEdit {
    background-color: #2c2c2e;
    border: 1px solid #3c3c40;
    border-radius: 7px;
    padding: 8px 12px;
    color: #ffffff;
    font-size: 13px;
    selection-background-color: #007aff;
}

QLineEdit:focus {
    border: 1.5px solid #007aff;
    background-color: #333336;
}

QLineEdit:read-only {
    color: #a0a0a5;
    background-color: #262629;
}

/* macOS Push Buttons */
QPushButton {
    background-color: #007aff;
    color: #ffffff;
    border: none;
    border-radius: 7px;
    padding: 7px 16px;
    font-size: 13px;
    font-weight: 600;
}

QPushButton:hover {
    background-color: #0071e3;
}

QPushButton:pressed {
    background-color: #005bb5;
}

QPushButton:disabled {
    background-color: #323235;
    color: #636366;
}

/* macOS Sekundäre Buttons (z.B. Ordner wählen, Einfügen) */
QPushButton#secondaryBtn {
    background-color: #323236;
    color: #f2f2f7;
    border: 1px solid #444448;
}

QPushButton#secondaryBtn:hover {
    background-color: #3c3c40;
    border-color: #55555a;
}

QPushButton#secondaryBtn:pressed {
    background-color: #28282b;
}

/* macOS Destructive / Stop Button */
QPushButton#cancelBtn {
    background-color: #ff453a;
    color: #ffffff;
    font-weight: 600;
}

QPushButton#cancelBtn:hover {
    background-color: #e0382e;
}

/* macOS Download-Button */
QPushButton#primaryDownloadBtn {
    background-color: #30d158;
    color: #ffffff;
    font-size: 14px;
    font-weight: 700;
    border-radius: 9px;
    padding: 10px 20px;
}

QPushButton#primaryDownloadBtn:hover {
    background-color: #28be4c;
}

QPushButton#primaryDownloadBtn:disabled {
    background-color: #323235;
    color: #636366;
}

/* macOS Dropdown / ComboBox */
QComboBox {
    background-color: #2c2c2e;
    border: 1px solid #3c3c40;
    border-radius: 7px;
    padding: 6px 12px;
    color: #ffffff;
    font-size: 13px;
    min-height: 22px;
}

QComboBox:hover {
    border-color: #007aff;
}

QComboBox::drop-down {
    border: none;
    width: 24px;
}

QComboBox QAbstractItemView {
    background-color: #2c2c2e;
    color: #ffffff;
    border: 1px solid #444448;
    border-radius: 7px;
    selection-background-color: #007aff;
    selection-color: #ffffff;
    padding: 4px;
}

/* Inset Cards (wie in macOS Systemeinstellungen) */
QGroupBox {
    background-color: #262629;
    border: 1px solid #36363a;
    border-radius: 10px;
    margin-top: 12px;
    padding: 14px;
    font-weight: 600;
    font-size: 12px;
    color: #8e8e93;
}

QGroupBox::title {
    subcontrol-origin: margin;
    subcontrol-position: top left;
    left: 12px;
    padding: 0 4px;
}

/* Radio Buttons & Checkboxes */
QRadioButton, QCheckBox {
    spacing: 8px;
    color: #e5e5ea;
    font-size: 13px;
    background-color: transparent;
}

QRadioButton::indicator, QCheckBox::indicator {
    width: 17px;
    height: 17px;
    border-radius: 8.5px;
    border: 1.5px solid #545458;
    background-color: #2c2c2e;
}

QCheckBox::indicator {
    border-radius: 5px;
}

QRadioButton::indicator:checked, QCheckBox::indicator:checked {
    border-color: #007aff;
    background-color: #007aff;
}

/* Progress Bar (Schlank wie macOS Safari / Finder) */
QProgressBar {
    background-color: #2c2c2e;
    border-radius: 4px;
    height: 8px;
    text-align: center;
    color: transparent;
}

QProgressBar::chunk {
    background-color: #007aff;
    border-radius: 4px;
}

/* Scrollbars im macOS-Stil */
QScrollBar:vertical {
    border: none;
    background-color: transparent;
    width: 8px;
    margin: 0px;
}

QScrollBar::handle:vertical {
    background-color: #48484a;
    min-height: 24px;
    border-radius: 4px;
}

QScrollBar::handle:vertical:hover {
    background-color: #636366;
}

QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
    height: 0px;
}

QScrollArea {
    border: none;
    background-color: transparent;
}
"""
