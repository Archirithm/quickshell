import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "rofi-launcher-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property int currentMode: 0
    property bool isClosing: false
    property string query: ""
    readonly property var modeLabels: ["Applications", "Windows", "Wallpapers"]

    property string previewImage: (currentMode === 2 && wallpaperPage.currentSelectedPreview !== "")
                                  ? wallpaperPage.currentSelectedPreview
                                  : (Appearance.currentWallpaperPreview !== "" ? Appearance.currentWallpaperPreview : "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_rofi/current")

    RofiStyle {
        id: rofiStyle
    }

    Process {
        id: syncGlobalWallpaper
        command: ["bash", "-c", "awww query | awk -F 'image: ' '{print $2}' | head -n 1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (path) => {
                let currentPath = path.trim().replace(/^"|"$/g, "");
                if (currentPath !== "")
                    Appearance.currentWallpaperPreview = "file://" + currentPath;
            }
        }
    }

    function resetSearch() {
        if (searchInput.text !== "")
            searchInput.text = ""
        if (root.query !== "")
            root.query = ""
    }

    function focusSearch() {
        searchInput.forceActiveFocus()
    }

    function decrementCurrentIndex() {
        if (root.currentMode === 0) appPage.decrementCurrentIndex()
        else if (root.currentMode === 1) windowPage.decrementCurrentIndex()
        else wallpaperPage.decrementCurrentIndex()
    }

    function incrementCurrentIndex() {
        if (root.currentMode === 0) appPage.incrementCurrentIndex()
        else if (root.currentMode === 1) windowPage.incrementCurrentIndex()
        else wallpaperPage.incrementCurrentIndex()
    }

    function activateSelected() {
        if (root.currentMode === 0) appPage.runSelectedApp()
        else if (root.currentMode === 1) windowPage.focusSelectedWindow()
        else wallpaperPage.applyWallpaper()
    }

    function setMode(mode) {
        if (root.currentMode === mode) {
            root.focusSearch()
            return
        }

        root.currentMode = mode
    }

    function prepareOpen(resetOpacity, delayFadeIn) {
        root.isClosing = false
        openFadeInDelay.stop()
        closeAnim.stop()

        if (resetOpacity) {
            mainUI.opacity = 0.0
            uiScale.xScale = rofiStyle.popinScale
            uiScale.yScale = rofiStyle.popinScale
        }

        root.resetSearch()

        if (delayFadeIn)
            openFadeInDelay.restart()
        else
            launcherFadeIn.restart()

        syncGlobalWallpaper.running = false
        syncGlobalWallpaper.running = true
        root.focusSearch()
    }

    function openWindow() {
        if (launcherFadeIn.running || (root.visible && !root.isClosing))
            return

        if (root.visible) {
            prepareOpen(false, false)
            return
        }

        root.visible = true
    }

    onVisibleChanged: {
        if (visible) {
            prepareOpen(true, true)
            uiTranslate.y = 0
        }
    }

    onCurrentModeChanged: {
        if (visible) {
            root.resetSearch()
            root.focusSearch()
        }
    }

    function requestClose() {
        if (!root.visible || root.isClosing)
            return

        root.isClosing = true
        openFadeInDelay.stop()
        launcherFadeIn.stop()
        closeAnim.restart()
    }

    function toggleWindow() {
        if (root.visible && !root.isClosing) requestClose()
        else openWindow()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    Rectangle {
        id: mainUI
        width: rofiStyle.windowWidth
        height: rofiStyle.windowHeight

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Sizes.barHeight / 2

        opacity: 0.0

        transformOrigin: Item.Center
        transform: [
            Translate {
                id: uiTranslate
                y: 0
            },
            Scale {
                id: uiScale
                origin.x: mainUI.width / 2
                origin.y: mainUI.height / 2
                xScale: rofiStyle.popinScale
                yScale: rofiStyle.popinScale
            }
        ]

        Timer {
            id: openFadeInDelay
            interval: 32
            repeat: false
            onTriggered: launcherFadeIn.restart()
        }

        ParallelAnimation {
            id: launcherFadeIn
            NumberAnimation {
                target: mainUI
                property: "opacity"
                to: 1.0
                duration: rofiStyle.openDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.fadeBezier
            }
            NumberAnimation {
                target: uiScale
                property: "xScale"
                to: 1.0
                duration: rofiStyle.openDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.openBezier
            }
            NumberAnimation {
                target: uiScale
                property: "yScale"
                to: 1.0
                duration: rofiStyle.openDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.openBezier
            }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: mainUI
                property: "opacity"
                to: 0.0
                duration: rofiStyle.closeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.fadeBezier
            }
            NumberAnimation {
                target: uiScale
                property: "xScale"
                to: rofiStyle.popinScale
                duration: rofiStyle.closeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.closeBezier
            }
            NumberAnimation {
                target: uiScale
                property: "yScale"
                to: rofiStyle.popinScale
                duration: rofiStyle.closeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: rofiStyle.closeBezier
            }

            onFinished: {
                root.visible = false
                root.isClosing = false
            }
        }

        color: Appearance.colors.colOnPrimaryFixed
        radius: rofiStyle.windowRadius
        focus: true

        Keys.onUpPressed: (event) => {
            root.decrementCurrentIndex()
            event.accepted = true
        }

        Keys.onDownPressed: (event) => {
            root.incrementCurrentIndex()
            event.accepted = true
        }

        Keys.onReturnPressed: (event) => {
            root.activateSelected()
            event.accepted = true
        }

        Keys.onEnterPressed: (event) => {
            root.activateSelected()
            event.accepted = true
        }

        Keys.onEscapePressed: (event) => {
            root.requestClose()
            event.accepted = true
        }

        Keys.onTabPressed: (event) => {
            root.setMode((root.currentMode + 1) % root.modeLabels.length)
            event.accepted = true
        }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id: globalMask
            anchors.fill: parent
            radius: rofiStyle.windowRadius
            visible: false
        }

        Item {
            anchors.fill: parent
            anchors.margins: rofiStyle.borderWidth
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: globalMask
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: rofiStyle.leftPaneWidth
                    Layout.fillHeight: true
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.previewImage
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: rofiStyle.windowWidth
                        sourceSize.height: rofiStyle.windowHeight
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: rofiStyle.panelPadding
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: rofiStyle.controlHeight
                            radius: rofiStyle.controlRadius
                            color: Appearance.colors.colOnPrimary
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: rofiStyle.controlPadding
                                spacing: rofiStyle.controlSpacing

                                Text {
                                    text: "  "
                                    color: Appearance.colors.colOnSurface
                                    font.family: Sizes.fontFamilyMono
                                    font.pixelSize: rofiStyle.fontPixelSize
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        anchors.fill: parent
                                        text: "Search"
                                        color: Appearance.applyAlpha(Appearance.colors.colOnSurface, 0.65)
                                        font.family: Sizes.fontFamilyMono
                                        font.pixelSize: rofiStyle.fontPixelSize
                                        verticalAlignment: Text.AlignVCenter
                                        visible: searchInput.text.length === 0
                                    }

                                    TextInput {
                                        id: searchInput
                                        anchors.fill: parent
                                        color: Appearance.colors.colOnSurface
                                        selectionColor: Appearance.colors.colPrimary
                                        selectedTextColor: Appearance.colors.colOnSecondary
                                        font.family: Sizes.fontFamilyMono
                                        font.pixelSize: rofiStyle.fontPixelSize
                                        verticalAlignment: TextInput.AlignVCenter
                                        clip: true
                                        focus: true
                                        selectByMouse: true

                                        onTextChanged: root.query = text

                                        Keys.onUpPressed: (event) => {
                                            root.decrementCurrentIndex()
                                            event.accepted = true
                                        }

                                        Keys.onDownPressed: (event) => {
                                            root.incrementCurrentIndex()
                                            event.accepted = true
                                        }

                                        Keys.onReturnPressed: (event) => {
                                            root.activateSelected()
                                            event.accepted = true
                                        }

                                        Keys.onEnterPressed: (event) => {
                                            root.activateSelected()
                                            event.accepted = true
                                        }

                                        Keys.onEscapePressed: (event) => {
                                            root.requestClose()
                                            event.accepted = true
                                        }

                                        Keys.onTabPressed: (event) => {
                                            root.setMode((root.currentMode + 1) % root.modeLabels.length)
                                            event.accepted = true
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: rofiStyle.modeSpacing

                            Repeater {
                                model: root.modeLabels

                                delegate: Rectangle {
                                    id: modeButton
                                    readonly property bool selected: root.currentMode === index

                                    Layout.preferredWidth: rofiStyle.modeButtonWidth
                                    Layout.preferredHeight: rofiStyle.controlHeight
                                    radius: rofiStyle.controlRadius
                                    color: selected ? Appearance.colors.colPrimary : Appearance.colors.colOnPrimary

                                    Text {
                                        id: modeLabel
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: modeButton.selected ? Appearance.colors.colOnSecondary : Appearance.colors.colPrimaryFixed
                                        font.family: Sizes.fontFamilyMono
                                        font.pixelSize: rofiStyle.fontPixelSize
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setMode(index)
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: rofiStyle.panelPadding
                        currentIndex: root.currentMode

                        AppPage {
                            id: appPage
                            query: root.query
                            onRequestCloseLauncher: root.requestClose()
                        }

                        WindowPage {
                            id: windowPage
                            query: root.query
                            onRequestCloseLauncher: root.requestClose()
                        }

                        WallpaperPage {
                            id: wallpaperPage
                            query: root.query
                            onRequestCloseLauncher: root.requestClose()
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Appearance.colors.colSecondaryContainer
            border.width: rofiStyle.borderWidth
            radius: rofiStyle.windowRadius
        }
    }
}
