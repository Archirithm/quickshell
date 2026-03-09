import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config 
import "file:///home/archirithm/.config/quickshell/JS/weather.js" as WeatherJS

Rectangle {
    id: root
    color: Colorscheme.surface_container_high 
    radius: 16

    // ================== 数据属性 ==================
    property string weatherTemp: "--°"
    property string weatherDesc: "Fetching"
    property string weatherCity: "..."
    property string weatherIcon: "cloud" 
    property bool isDay: true
    property var forecastData: [] 

    // ================== 原生 JS 数据获取 ==================
    function fetchData() {
        WeatherJS.fetchLocationAndWeather(function(data) {
            if (!data) {
                root.weatherDesc = "Error";
                return;
            }
            
            // 1. 更新当前天气
            root.weatherCity = data.locName;
            root.weatherTemp = Math.round(data.current.temperature_2m) + "°";
            root.weatherDesc = WeatherJS.getWeatherDesc(data.current.weather_code);
            root.isDay = data.current.is_day === 1;
            root.weatherIcon = WeatherJS.getMaterialIcon(data.current.weather_code);

            // 2. 解析未来 6 天的数据
            var tempForecast = [];
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            
            for (var i = 1; i < Math.min(7, data.daily.time.length); i++) {
                var dateObj = new Date(data.daily.time[i]);
                tempForecast.push({
                    day: days[dateObj.getDay()],
                    temp: Math.round(data.daily.temperature_2m_max[i]) + "°",
                    desc: WeatherJS.getWeatherDesc(data.daily.weather_code[i]),
                    icon: WeatherJS.getMaterialIcon(data.daily.weather_code[i])
                });
            }
            root.forecastData = tempForecast;
        });
    }

    onVisibleChanged: if (visible) fetchData()
    Component.onCompleted: fetchData()
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: fetchData() }

    // ================== 界面布局 ==================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // 【左半边】：当天天气
        ColumnLayout {
            Layout.preferredWidth: 35 
            Layout.fillWidth: true 
            Layout.fillHeight: true
            spacing: 2
            
            // 顶部：图标 + 温度
            RowLayout {
                spacing: 8
                
                Text {
                    text: root.weatherIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: Colorscheme.tertiary
                    Layout.alignment: Qt.AlignVCenter
                }

                Text { 
                    text: root.weatherTemp
                    color: Colorscheme.on_surface 
                    font.family: Sizes.fontFamily
                    font.pixelSize: 28 
                    font.bold: true 
                }
            }

            // 底部：独立显示天气描述和城市
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Layout.topMargin: 2
                
                Text { 
                    text: root.weatherDesc
                    color: Colorscheme.on_surface_variant
                    font.family: Sizes.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                Text { 
                    text: root.weatherCity
                    color: Colorscheme.outline
                    font.family: Sizes.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // 【中轴线】
        Rectangle {
            width: 1
            Layout.fillHeight: true
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            color: Colorscheme.outline_variant
        }

        // 【右半边】：未来 6 天的宽裕排列
        RowLayout {
            Layout.preferredWidth: 95 
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            
            Repeater {
                model: root.forecastData.length > 0 ? root.forecastData : [
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}, 
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}, 
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}, 
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}, 
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}, 
                    {"day": "-", "temp": "--", "desc": "", "icon": "cloud"}
                ]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Colorscheme.surface_container_highest 
                    radius: 10
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text { 
                            text: modelData.day 
                            color: Colorscheme.on_surface_variant
                            font.pixelSize: 11
                            font.bold: true 
                            font.family: Sizes.fontFamily
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Text {
                            text: modelData.icon || "cloud"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Colorscheme.tertiary
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Text { 
                            text: modelData.temp
                            color: Colorscheme.on_surface
                            font.pixelSize: 12
                            font.bold: true 
                            font.family: Sizes.fontFamily
                            Layout.alignment: Qt.AlignHCenter 
                        }
                    }
                }
            }
        }
    }
}
