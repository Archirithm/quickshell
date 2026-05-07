import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Clavis.Niri 1.0
import qs.Common

Item {
    id: root

    signal requestCloseLauncher()

    property var filteredWindows: []

    function decrementCurrentIndex() { windowsList.decrementCurrentIndex() }
    function incrementCurrentIndex() { windowsList.incrementCurrentIndex() }
    function forceSearchFocus() { searchBox.forceActiveFocus() }

    function cleanAppName(rawName, isAppId) {
        if (!rawName) return ""
        let name = rawName

        if (isAppId) {
            name = name.replace(/^([a-z0-9\-]+\.)+/gi, "")
            name = name.replace(/\.desktop$/gi, "")
        } else {
            name = name.replace(/\s*[-—|]\s*(Mozilla Firefox|Google Chrome|Chromium|Brave|Edge|Vivaldi|Visual Studio Code|Kate|KWrite).*$/gi, "")
        }

        return name
    }

    function search(text) {
        filteredWindows = Niri.searchWindows(text)
        if (windowsList.currentIndex >= filteredWindows.length) {
            windowsList.currentIndex = 0
        }
    }

    Connections {
        target: Niri
        function onWindowsChanged() {
            if (root.visible) {
                root.search(searchBox.text)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchBox.text = ""
            search("")
        }
    }

    function highlightText(fullText, query) {
        let safeText = fullText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        if (!query || query.trim() === "") return safeText
        let escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let regex = new RegExp("(" + escapedQuery + ")", "gi")
        return safeText.replace(regex, "<u><b>$1</b></u>")
    }

    TextInput {
        id: searchBox
        x: -1000
        y: -1000
        width: 0
        height: 0
        opacity: 0
        visible: true

        onTextChanged: {
            root.search(text)
            windowsList.currentIndex = 0
        }
        Keys.onReturnPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onEnterPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onUpPressed: (event) => { windowsList.decrementCurrentIndex(); event.accepted = true }
        Keys.onDownPressed: (event) => { windowsList.incrementCurrentIndex(); event.accepted = true }
    }

    Item {
        anchors.fill: parent

        Text {
            anchors.centerIn: parent
            text: "No windows opened."
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: 16
            visible: root.filteredWindows.length === 0
        }

        ListView {
            id: windowsList
            width: parent.width
            height: 504
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            model: root.filteredWindows

            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: height - 56

            highlight: Rectangle {
                color: Appearance.colors.colPrimary
                radius: 12
            }
            highlightMoveDuration: 0

            delegate: Item {
                id: delegateItem
                width: ListView.view.width
                height: 56

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        windowsList.currentIndex = index
                        focusSelectedWindow()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 16

                    Item {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36

                        Image {
                            anchors.fill: parent
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            source: modelData.iconPath || "image://icon/application-x-executable"
                        }
                    }

                    Text {
                        text: root.highlightText(root.cleanAppName(modelData.title, false), searchBox.text)
                        textFormat: Text.StyledText
                        color: delegateItem.ListView.isCurrentItem ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                        font.pixelSize: 16
                        font.bold: false
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.highlightText(root.cleanAppName(modelData.appName || modelData.appId, true), searchBox.text)
                        textFormat: Text.StyledText
                        color: delegateItem.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.7) : Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }
    }

    function focusSelectedWindow() {
        if (root.filteredWindows.length > 0 && windowsList.currentIndex >= 0) {
            let win = root.filteredWindows[windowsList.currentIndex]
            Niri.focusWindow(win.id)
        }
    }
}
