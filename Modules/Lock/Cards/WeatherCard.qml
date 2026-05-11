import QtQuick
import QtQuick.Layouts
import Clavis.Weather 1.0
import qs.Common

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 160 
    
    color: Appearance.colors.colLayer2 
    radius: Sizes.lockCardRadius

    readonly property string temp: WeatherPlugin.hasValidData ? Math.round(WeatherPlugin.currentTemperatureC) + "°" : "--"
    readonly property string cond: WeatherPlugin.loading ? "Loading..." : (WeatherPlugin.currentWeatherText || "Unknown")
    readonly property string loc: WeatherPlugin.locationName || "Location"
    readonly property string iconName: WeatherPlugin.currentIconName || "cloud"

    Component.onCompleted: {
        if (!WeatherPlugin.hasValidData)
            WeatherPlugin.refresh();
    }

    // ================== 界面布局 ==================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24 
        spacing: 15

        // 左侧：大图标
        Text {
            text: root.iconName
            font.family: "Material Symbols Outlined"
            font.pixelSize: 64
            color: Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignVCenter
        }

        // 右侧：信息区
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            // 1. 巨大的温度数字
            Text {
                text: root.temp
                color: Appearance.colors.colOnSurface
                font.family: Sizes.fontFamily
                font.pixelSize: 42 
                font.bold: true
                Layout.fillWidth: true
            }

            // 2. 城市名 (小标题)
            Text {
                text: root.loc ? root.loc : "Location"
                color: Appearance.colors.colPrimary
                font.family: Sizes.fontFamily
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
                opacity: 0.8
            }

            // 3. 天气状况
            Text {
                text: root.cond 
                color: Appearance.colors.colOnSurfaceVariant
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                Layout.fillWidth: true
                elide: Text.ElideRight
                Layout.topMargin: 4
            }
        }
    }
}
