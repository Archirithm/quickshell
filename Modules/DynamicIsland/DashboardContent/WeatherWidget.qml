import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root
    // 使用主题色作为卡片底色
    color: Colorscheme.surface_container_high 
    radius: 16

    // ================== 图标数据 ==================
    QtObject {
        id: icons
        property string sunny: "M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0 2c1.65 0 3 1.35 3 3s-1.35 3-3 3-3-1.35-3-3 1.35-3 3-3zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0-.39.39-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0 .39-.39.39-1.03 0-1.41l-1.06-1.06zm1.06-10.96c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06zM7.05 18.36c.39-.39.39-1.03 0-1.41-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06z"
        property string moon: "M10 2c-1.82 0-3.53.5-5 1.35C7.99 5.08 10 8.3 10 12s-2.01 6.92-5 8.65C6.47 21.5 8.18 22 10 22c5.52 0 10-4.48 10-10S15.52 2 10 2z"
        property string cloudy: "M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4 0-2.05 1.53-3.76 3.56-3.97l1.07-.11.5-.95C8.08 7.14 9.94 6 12 6c2.62 0 4.88 1.86 5.39 4.43l.3 1.5 1.53.11c1.56.1 2.78 1.41 2.78 2.96 0 1.65-1.35 3-3 3z"
        property string rain: "M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM10 22c-.55 0-1-.45-1-1v-4c0-.55.45-1 1-1s1 .45 1 1v4c0 .55-.45 1-1 1zm4 0c-.55 0-1-.45-1-1v-4c0-.55.45-1 1-1s1 .45 1 1v4c0 .55-.45 1-1 1zm-8 0c-.55 0-1-.45-1-1v-4c0-.55.45-1 1-1s1 .45 1 1v4c0 .55-.45 1-1 1z"
        property string snow: "M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM12 21.5l1.5-1.5-1.5-1.5-1.5 1.5 1.5 1.5zm-5 0l1.5-1.5-1.5-1.5-1.5 1.5 1.5 1.5zm10 0l1.5-1.5-1.5-1.5-1.5 1.5 1.5 1.5z"

        function getPath(desc, isDay) {
            if (!desc) return cloudy;
            let d = desc.toLowerCase();
            if (d.includes("sun") || d.includes("clear") || d.includes("main")) return isDay ? sunny : moon;
            if (d.includes("rain") || d.includes("drizzle") || d.includes("shower")) return rain;
            if (d.includes("snow") || d.includes("ice")) return snow;
            return cloudy;
        }
    }

    // ================== 后台数据获取 ==================
    property string weatherTemp: "--°"
    property string weatherDesc: "Fetching"
    property string weatherCity: "..."
    property string weatherIconPath: icons.cloudy
    property bool isDay: true
    property var forecastData: [] 

    Process {
        id: weatherProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var json = JSON.parse(data);
                    if(json.temp) root.weatherTemp = json.temp;
                    if(json.desc) root.weatherDesc = json.desc;
                    if(json.city) root.weatherCity = json.city;
                    if (json.isDay !== undefined) root.isDay = json.isDay;
                    if (json.forecast && json.forecast.length > 0) root.forecastData = json.forecast;
                    root.weatherIconPath = icons.getPath(json.desc, root.isDay);
                } catch(e) { console.log("Weather JSON error: " + e); }
            }
        }
    }
    onVisibleChanged: if (visible) weatherProc.running = true

    // ================== 横向界面的精调 ==================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // 【左半边】：当天天气 (全新纵向堆叠排布，告别文字截断)
        ColumnLayout {
            // 保持左侧的小权重占比
            Layout.preferredWidth: 35 
            Layout.fillWidth: true 
            Layout.fillHeight: true
            spacing: 2
            
            // 顶部：图标 + 温度
            RowLayout {
                spacing: 8
                Item {
                    width: 32; height: 32
                    Layout.alignment: Qt.AlignVCenter
                    Shape {
                        scale: 32/24; anchors.centerIn: parent; width: 24; height: 24
                        // 图标采用主题的主打色 (或者 tertiary 色)
                        ShapePath { strokeWidth: 0; fillColor: Colorscheme.tertiary; PathSvg { path: root.weatherIconPath } }
                    }
                }
                Text { 
                    text: root.weatherTemp
                    color: Colorscheme.on_surface 
                    font.family: Sizes.fontFamily
                    font.pixelSize: 28 
                    font.bold: true 
                }
            }

            // 底部：独立显示天气描述和城市，利用全部宽度
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
            // 根据你的要求，大幅增加右侧的 Flex 权重
            Layout.preferredWidth: 95 
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            
            Repeater {
                model: root.forecastData.length > 0 ? root.forecastData : [
                    {"day": "-", "temp": "--", "desc": ""}, {"day": "-", "temp": "--", "desc": ""}, 
                    {"day": "-", "temp": "--", "desc": ""}, {"day": "-", "temp": "--", "desc": ""}, 
                    {"day": "-", "temp": "--", "desc": ""}, {"day": "-", "temp": "--", "desc": ""}
                ]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // 单个日期的卡片底色
                    color: Colorscheme.surface_container_highest 
                    radius: 10
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Text { 
                            text: modelData.day 
                            color: Colorscheme.on_surface_variant
                            font.pixelSize: 11; font.bold: true; font.family: Sizes.fontFamily
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Item {
                            width: 18; height: 18
                            Layout.alignment: Qt.AlignHCenter 
                            Shape {
                                scale: 18/24; anchors.centerIn: parent; width: 24; height: 24
                                ShapePath { 
                                    strokeWidth: 0; fillColor: Colorscheme.tertiary
                                    PathSvg { path: icons.getPath(modelData.desc, true) } 
                                }
                            }
                        }
                        
                        Text { 
                            text: modelData.temp
                            color: Colorscheme.on_surface
                            font.pixelSize: 12; font.bold: true; font.family: Sizes.fontFamily
                            Layout.alignment: Qt.AlignHCenter 
                        }
                    }
                }
            }
        }
    }
}
