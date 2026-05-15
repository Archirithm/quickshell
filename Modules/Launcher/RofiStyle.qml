import QtQuick

QtObject {
    readonly property real resolutionScale: 4 / 3

    function scaled(value) {
        return Math.round(value * resolutionScale)
    }

    readonly property int windowWidth: scaled(1000)
    readonly property int windowHeight: scaled(498)
    readonly property int windowRadius: scaled(15)
    readonly property int controlRadius: scaled(10)
    readonly property int borderWidth: scaled(2)

    readonly property real contentWidth: windowWidth - borderWidth * 2
    readonly property real leftPaneWidth: contentWidth / 2
    readonly property real paneInnerWidth: leftPaneWidth - panelPadding * 2
    readonly property int panelPadding: scaled(20)
    readonly property int controlPadding: scaled(15)
    readonly property int controlHeight: scaled(48)
    readonly property int controlSpacing: scaled(10)
    readonly property int modeSpacing: scaled(20)
    readonly property real modeButtonWidth: (paneInnerWidth - modeSpacing * 2) / 3

    readonly property int listRows: 8
    readonly property int listSpacing: scaled(10)
    readonly property int rowHeight: scaled(48)
    readonly property int listStep: rowHeight + listSpacing
    readonly property int listHeight: listRows * rowHeight + (listRows - 1) * listSpacing
    readonly property int itemPadding: scaled(8)
    readonly property int itemSpacing: scaled(15)
    readonly property int iconSize: scaled(32)
    readonly property int wallpaperThumbWidth: scaled(64)
    readonly property int wallpaperThumbHeight: scaled(32)

    readonly property int fontPixelSize: scaled(14)
    readonly property int secondaryFontPixelSize: scaled(12)

    readonly property int openDuration: 300
    readonly property int closeDuration: 220
    readonly property real popinScale: 0.7
    readonly property var openBezier: [0, 0.85, 0.3, 1, 1, 1]
    readonly property var closeBezier: [0.24, 0.9, 0.25, 0.91, 1, 1]
    readonly property var fadeBezier: [0.7, 0.6, 0.1, 1.1, 1, 1]
}
