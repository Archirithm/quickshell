import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import "file:///home/archirithm/.config/quickshell/JS/weather.js" as WeatherJS

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 160 
    
    color: Appearance.colors.colLayer2 
    radius: Sizes.lockCardRadius

    // ================== 数据属性 ==================
    property string temp: "--"
    property string cond: "Loading..."
    property string loc: ""
    property string iconName: "cloud"
    property bool isDay: true

    // ================== 原生 JS 数据获取 ==================
    function fetchData() {
        WeatherJS.fetchLocationAndWeather(function(data) {
            if (!data) {
                root.cond = "Error";
                return;
            }
            
            root.temp = Math.round(data.current.temperature_2m) + "°";
            root.cond = WeatherJS.getWeatherDesc(data.current.weather_code);
            root.loc = data.locName;
            root.isDay = data.current.is_day === 1;
            root.iconName = WeatherJS.getMaterialIcon(data.current.weather_code);
        });
    }

    onVisibleChanged: if (visible) fetchData()
    Component.onCompleted: fetchData()
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: fetchData() }

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
