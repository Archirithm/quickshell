import QtQuick
import qs.config

Rectangle {
    id: root

    property string viewName: "info"
    property string iconName: "notifications"
    property color activeColor: Appearance.colors.colSecondaryContainer
    property color activeContentColor: Appearance.colors.colOnSecondaryContainer
    readonly property bool isHovered: mouseArea.containsMouse
    readonly property bool isActive: WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === viewName

    implicitHeight: isHovered ? 34 : 28
    implicitWidth: isHovered ? 34 : 28
    radius: height / 2
    color: activeColor

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    function toggleView() {
        if (WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === viewName) {
            WidgetState.leftSidebarOpen = false;
            return;
        }

        WidgetState.leftSidebarView = viewName;
        WidgetState.leftSidebarOpen = true;
    }

    Text {
        anchors.centerIn: parent
        text: root.iconName
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.isHovered ? 18 : 16
        color: root.activeContentColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleView()
    }
}
