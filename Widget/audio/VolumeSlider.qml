import QtQuick
import QtQuick.Layouts
import qs.Widget.common

Rectangle {
    id: root
    property var node
    property bool isHeadphone: false
    property var theme: Theme {}

    Layout.fillWidth: true
    height: 28
    color: Qt.rgba(theme.primary.r, theme.primary.g, theme.primary.b, 0.1)
    radius: 14

    Rectangle {
        height: parent.height
        width: node ? parent.width * node.audio.volume : 0
        color: theme.primary
        radius: 14
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function setVol(mouse) {
            if (!node) return
            let v = mouse.x / width
            if (v < 0) v = 0; if (v > 1) v = 1;
            node.audio.volume = v
            if (node.audio.muted) node.audio.muted = false
        }
        onPressed: (mouse) => setVol(mouse)
        onPositionChanged: (mouse) => setVol(mouse)
    }

    Text {
        anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter
        text: (node && node.audio.muted) ? "\uf6a9" : (root.isHeadphone ? "\uf025" : "\uf028")
        font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 12; color: "white"
    }
}
