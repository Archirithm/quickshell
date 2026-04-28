import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Clavis.Niri 1.0
import qs.config

Item {
    id: root

    property string screenName: ""
    property var displayWorkspaces: []

    implicitHeight: 36
    implicitWidth: layout.width + 24

    function refreshWorkspaces() {
        const filtered = Niri.workspacesForOutput(root.screenName)
        root.displayWorkspaces = (filtered.length > 0 || root.screenName !== "" || Niri.outputs.count > 1)
                ? filtered
                : Niri.workspacesForOutput("")
    }

    Component.onCompleted: refreshWorkspaces()
    onScreenNameChanged: refreshWorkspaces()

    Connections {
        target: Niri
        function onWorkspacesChanged() { root.refreshWorkspaces() }
        function onWindowsChanged() { root.refreshWorkspaces() }
        function onOutputsChanged() { root.refreshWorkspaces() }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colorscheme.background
        radius: height / 2
        visible: false
    }

    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: Qt.alpha(Colorscheme.shadow, 0.4)
        shadowBlur: 0.8
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: root.displayWorkspaces

            delegate: Item {
                id: delegateRoot

                property bool active: modelData.isActive
                property bool hasWindows: modelData.windowCount > 0
                property bool isHovered: mouseArea.containsMouse

                implicitWidth: (active || isHovered) ? 32 : 12
                implicitHeight: 12

                Behavior on implicitWidth {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: height / 2

                    color: delegateRoot.active ? Colorscheme.primary
                         : delegateRoot.hasWindows ? Colorscheme.on_surface
                         : delegateRoot.isHovered ? Colorscheme.surface_variant
                         : Colorscheme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspaceById(modelData.id)
                }
            }
        }
    }
}
