import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.config

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 280
    
    color: Colorscheme.surface_container
    radius: Sizes.lockCardRadius

    // ================== 数据属性 (初始化为 0 防止 undefined 报错) ==================
    property var sysData: ({
        cpu: { value: 0, text: "--%" },
        ram: { value: 0, text: "--%" },
        disk: { value: 0, text: "--%" },
        temp: { value: 0, text: "--°C" }
    })

    // ================== 数据获取 ==================
    Process {
        id: monitorProc
        // 确保调用的是 python3 且路径正确
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_monitor.py"]
        running: true 
        
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    // 解析 JSON 并更新属性
                    var json = JSON.parse(data.trim());
                    root.sysData = json;
                } catch(e) {
                    console.log("SysMonitor JSON Error: " + e);
                }
            }
        }
    }

    // 定时刷新 (每 2 秒一次)
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: monitorProc.running = true
    }
    
    // 界面显示时立即刷新一次
    Component.onCompleted: monitorProc.running = true

    // ================== 网格布局 ==================
    GridLayout {
        anchors.fill: parent
        anchors.margins: Sizes.lockCardPadding
        columns: 2
        rowSpacing: 15
        columnSpacing: 15

        // 1. CPU (紫色)
        SystemCircle { 
            title: "CPU"
            icon: "" // Nerd Font Chip
            value: root.sysData.cpu.value
            display: root.sysData.cpu.text
            accent: "#C586C0" 
        }

        // 2. Temp (红/橙色)
        SystemCircle { 
            title: "TEMP"
            icon: "" // Thermometer
            value: root.sysData.temp.value
            display: root.sysData.temp.text
            accent: "#F08080" 
        }

        // 3. RAM (蓝色)
        SystemCircle { 
            title: "RAM"
            icon: "\ue266" // Memory
            value: root.sysData.ram.value
            display: root.sysData.ram.text
            accent: "#569CD6" 
        }

        // 4. Disk (青/黄色)
        SystemCircle { 
            title: "DISK"
            icon: "" // HDD
            value: root.sysData.disk.value
            display: root.sysData.disk.text
            accent: "#DCDCAA" 
        }
    }

    // ================== 圆形组件封装 ==================
    component SystemCircle: Item {
        property string title
        property string icon
        property real value: 0.0
        property string display: ""
        property color accent
        
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        // 每个格子的背景
        Rectangle {
            anchors.fill: parent
            color: Colorscheme.surface_container_highest
            radius: 16
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            // 进度环容器
            Item {
                width: 60; height: 60
                Layout.alignment: Qt.AlignHCenter
                
                // 旋转 -90 度，让进度从顶部开始
                Shape {
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height
                    rotation: -90
                    
                    // 1. 底部轨道 (暗色)
                    ShapePath {
                        strokeColor: Qt.rgba(Colorscheme.on_surface.r, Colorscheme.on_surface.g, Colorscheme.on_surface.b, 0.1)
                        strokeWidth: 6
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 30; centerY: 30; radiusX: 27; radiusY: 27; startAngle: 0; sweepAngle: 360 }
                    }
                    
                    // 2. 进度条 (亮色)
                    ShapePath {
                        strokeColor: accent
                        strokeWidth: 6
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { 
                            centerX: 30; centerY: 30; radiusX: 27; radiusY: 27; 
                            startAngle: 0; 
                            // 确保 value 不为 undefined 且在 0-1 之间
                            sweepAngle: 360 * (Math.min(Math.max(value, 0), 1))
                        }
                    }
                }
                
                // 中间的图标
                Text {
                    anchors.centerIn: parent
                    text: icon
                    color: accent
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 22
                }
            }
            
            // 底部文字 (标题 + 数值)
            Text {
                text: display
                color: Colorscheme.on_surface
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
