import QtQuick
import Quickshell
import qs.Common
import qs.Components

Rectangle {
    id: root

    property bool isHovered: mouseArea.containsMouse
    readonly property bool active: WidgetState.qsOpen && WidgetState.qsView === "settings"

    color: active ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
    radius: height / 2
    implicitHeight: isHovered ? 34 : 28
    implicitWidth: isHovered ? 34 : 28

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.active) {
                WidgetState.qsOpen = false;
            } else {
                WidgetState.qsView = "settings";
                WidgetState.qsOpen = true;
            }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: "settings"
        iconSize: root.isHovered ? 20 : 18
        fill: root.active ? 1 : 0
        color: root.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3
    }
}
