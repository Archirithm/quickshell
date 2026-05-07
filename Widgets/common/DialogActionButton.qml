import QtQuick
import qs.Common

Rectangle {
    id: root

    property alias text: label.text
    property bool filled: false
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 34
    radius: height / 2
    color: filled
        ? (buttonMouse.pressed ? Appearance.colors.colLayer4Active : buttonMouse.containsMouse ? Appearance.colors.colLayer4Hover : Appearance.colors.colLayer4)
        : (buttonMouse.pressed ? Appearance.colors.colLayer3Active : buttonMouse.containsMouse ? Appearance.colors.colLayer3Hover : "transparent")

    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        id: label
        anchors.centerIn: parent
        font.pixelSize: 12
        font.bold: true
        color: Appearance.colors.colPrimary

        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
