import QtQuick
import qs.config

Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property color iconColor: Appearance.colors.colOnSurface
    property color titleColor: Appearance.colors.colOnSurface
    property int headerLeftMargin: 18
    property int headerTopMargin: 16
    property int headerSpacing: 6
    default property alias content: contentLayer.data

    radius: 34
    color: Qt.rgba(Appearance.colors.colLayer3.r, Appearance.colors.colLayer3.g, Appearance.colors.colLayer3.b, 0.93)
    border.width: 1
    border.color: Qt.rgba(Appearance.colors.colOutlineVariant.r, Appearance.colors.colOutlineVariant.g, Appearance.colors.colOutlineVariant.b, 0.26)
    clip: true

    Item {
        id: contentLayer
        anchors.fill: parent
    }

    Row {
        id: headerRow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: root.headerLeftMargin
        anchors.topMargin: root.headerTopMargin
        spacing: root.headerSpacing
        visible: root.icon.length > 0 || root.title.length > 0
        z: 2

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.iconColor
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.title.length > 0
            text: root.title
            color: root.titleColor
            font.family: "LXGW WenKai GB Screen"
            font.pixelSize: 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
