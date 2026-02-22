import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.config

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 160 // 配合之前的布局高度
    
    color: Colorscheme.surface_container 
    radius: Sizes.lockCardRadius

    // ================== 数据属性 ==================
    property string temp: "--"
    property string cond: "Loading..."
    property string loc: ""
    property string iconPath: icons.cloudy
    property bool isDay: true

    // ================== 图标定义 (保持不变) ==================
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

    // ================== 数据获取 ==================
    Process {
        id: weatherProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py"]
        running: true 
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var json = JSON.parse(data.trim());
                    root.temp = json.temp;
                    root.cond = json.desc;
                    root.loc = json.city;
                    if (json.isDay !== undefined) root.isDay = json.isDay;
                    root.iconPath = icons.getPath(json.desc, root.isDay);
                } catch(e) {
                    root.cond = "Error";
                }
            }
        }
    }
    onVisibleChanged: if (visible) weatherProc.running = true

    // ================== 界面布局 ==================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24 // 增加内边距
        spacing: 15

        // 左侧：大图标
        Item {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignVCenter
            
            Shape {
                scale: 64 / 24
                anchors.centerIn: parent
                width: 24; height: 24
                ShapePath {
                    strokeWidth: 0
                    fillColor: Colorscheme.primary 
                    PathSvg { path: root.iconPath }
                }
            }
        }

        // 右侧：信息区
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            // 1. 巨大的温度数字
            Text {
                text: root.temp
                color: Colorscheme.on_surface
                font.family: Sizes.fontFamily
                // 【修改】字体加大到 42
                font.pixelSize: 42 
                font.bold: true
                Layout.fillWidth: true
            }

            // 2. 城市名 (小标题)
            Text {
                text: root.loc ? root.loc : "Location"
                color: Colorscheme.primary
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
                color: Colorscheme.on_surface_variant
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                Layout.fillWidth: true
                elide: Text.ElideRight
                Layout.topMargin: 4
            }
        }
    }
}
