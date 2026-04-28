import QtQuick
import Clavis.Sysmon 1.0

Rectangle {
    width: 300
    height: 100
    color: "#2e3440"
    radius: 12

    Text {
        anchors.centerIn: parent
        color: "#d8dee9"
        font.pixelSize: 24
        font.family: "sans-serif"
        text: "CPU Usage: " + SysmonPlugin.cpuUsage.toFixed(1) + "%"
    }
}
