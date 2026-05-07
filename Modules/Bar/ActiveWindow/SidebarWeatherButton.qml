import QtQuick
import QtQuick.Layouts
import Clavis.Weather 1.0
import qs.Common

Item {
    id: root

    readonly property bool isHovered: mouseArea.containsMouse
    readonly property string temperatureText: WeatherPlugin.hasValidData ? Math.round(WeatherPlugin.currentTemperatureC) + "°" : "--°"

    implicitHeight: isHovered ? 34 : 28
    implicitWidth: isHovered ? contentRow.implicitWidth + 16 : 28
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function toggleView() {
        if (WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === "weather") {
            WidgetState.leftSidebarOpen = false;
            return;
        }

        WidgetState.leftSidebarView = "weather";
        WidgetState.leftSidebarOpen = true;
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: WeatherPlugin.currentIconName || "cloud"
            font.family: "Material Symbols Rounded"
            font.variableAxes: { "FILL": 1 }
            font.pixelSize: 20
            color: Appearance.colors.colOnLayer2
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 160 } }
        }

        Text {
            visible: root.isHovered
            opacity: root.isHovered ? 1 : 0
            text: root.temperatureText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
            color: Appearance.colors.colOnLayer2
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleView()
    }
}
