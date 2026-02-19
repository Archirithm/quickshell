import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root

    // ================= 1. 样式与尺寸 =================
    color: Colorsheme.background
    radius: Sizes.cornerRadius
    clip: true // 裁剪内容，用于展开动画

    property bool expanded: false
    property int barHeight: Sizes.barHeight
    
    // 动态宽度：展开显示全部，收起只显示 RAM
    width: expanded ? (contentLayout.implicitWidth + 24) : (ramGroup.implicitWidth + 24)
    height: barHeight

    implicitWidth: width
    implicitHeight: height

    Behavior on width { 
        NumberAnimation { duration: 300; easing.type: Easing.OutQuart } 
    }

    // ================= 2. 数据源 =================
    property string ramText: "..."
    property string cpuText: "0%"
    property string tempText: "0°C"
    property string diskText: "0%" // 新增硬盘文字
    
    property int tempValue: 0 
    property int cpuValue: 0
    property int diskValue: 0      // 新增硬盘数值(用于变色)

    Process {
        id: proc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_monitor.py"]
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let json = JSON.parse(data.trim());
                    
                    root.ramText = json.ram.text;   // 现在这里是 "x.xG"
                    root.cpuText = json.cpu.text;
                    root.tempText = json.temp.text;
                    root.diskText = json.disk.text; // 获取硬盘百分比
                    
                    root.cpuValue = parseInt(json.cpu.text);
                    root.tempValue = parseInt(json.temp.text);
                    root.diskValue = parseInt(json.disk.text);
                } catch(e) {
                    console.log("SysMonitor JSON Error: " + e)
                }
            }
        }
    }

    Timer { 
        interval: 2000; running: true; repeat: true; triggeredOnStart: true; 
        onTriggered: proc.running = true 
    }

    // ================= 3. 颜色逻辑 =================
    readonly property color colorNormal: "#ffffff"
    readonly property color colorWarn: "#f9e2af"
    readonly property color colorCrit: "#f38ba8"

    function getTempColor(val) {
        if (val > 85) return colorCrit;
        if (val > 70) return colorWarn;
        return colorNormal;
    }
    
    function getCpuColor(val) {
        if (val > 90) return colorCrit;
        if (val > 70) return colorWarn;
        return colorNormal;
    }

    // 硬盘颜色：超过 90% 变红，超过 80% 变黄
    function getDiskColor(val) {
        if (val > 90) return colorCrit;
        if (val > 80) return colorWarn;
        return colorNormal;
    }

    // ================= 4. 交互区域 =================
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.expanded = !root.expanded;
            proc.running = true; 
        }
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["gnome-system-monitor"]);
            }
        }
    }

    // ================= 5. 布局内容 =================
    RowLayout {
        id: contentLayout
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12
        spacing: 12
        
        // 从右向左排：RAM 在最右边
        layoutDirection: Qt.RightToLeft

        // --- 1. RAM (常驻) ---
        RowLayout {
            id: ramGroup
            spacing: 4
            Text { 
                text: "" 
                color: "#a6e3a1" // 绿色图标
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.ramText // 显示 GB
                color: "#ffffff" 
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }

        // --- 2. Disk (展开显示) ---
        RowLayout {
            id: diskGroup
            spacing: 4
            
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text { 
                text: "" // 硬盘图标
                color: root.getDiskColor(root.diskValue)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.diskText // 显示 %
                color: root.getDiskColor(root.diskValue)
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }

        // --- 3. Temp (展开显示) ---
        RowLayout {
            id: tempGroup
            spacing: 4
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text { 
                text: "" 
                color: root.getTempColor(root.tempValue)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.tempText 
                color: root.getTempColor(root.tempValue)
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }

        // --- 4. CPU (展开显示) ---
        RowLayout {
            id: cpuGroup
            spacing: 4
            visible: opacity > 0
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            Text { 
                text: "" 
                color: root.getCpuColor(root.cpuValue)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
            }
            Text { 
                text: root.cpuText 
                color: root.getCpuColor(root.cpuValue)
                font.family: "LXGW WenKai GB Screen"
                font.bold: true 
                font.pixelSize: 13 
            }
        }
    }
}
