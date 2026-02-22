import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Rectangle {
    id: root

    // ============================================================
    // 样式配置
    // ============================================================
    color: Colorscheme.background      
    radius: Sizes.cornerRadius             
    
    property bool expanded: false
    property string currentProfile: "balanced" 

    property int barHeight: Sizes.barHeight        
    property int collapsedWidth: 36   

    // 【修改点 1】缩短展开后的总宽度
    // 之前是 120，现在改为 108。虽然间距大了，但通过减少边缘留白，整体更短更紧凑。
    property int expandedWidth: 108   

    implicitWidth: width 
    implicitHeight: height

    width: expanded ? expandedWidth : collapsedWidth
    height: barHeight
    
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

    // ============================================================
    // 逻辑 (不变)
    // ============================================================
    Process {
        id: getProc
        command: ["powerprofilesctl", "get"]
        stdout: SplitParser {
            onRead: (data) => {
                let val = data.trim();
                if (val !== "") root.currentProfile = val;
            }
        }
    }

    function setProfile(mode) {
        root.currentProfile = mode;
        let cmd = "powerprofilesctl set " + mode;
        setProc.command = ["bash", "-c", cmd];
        setProc.running = true;
        root.expanded = false;
    }

    Process { id: setProc }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: getProc.running = true
    }

    QtObject {
        id: style
        function getIcon(mode) {
            switch(mode) {
                case "performance": return "󱐋";
                case "power-saver": return "";
                default: return ""; 
            }
        }
        function getColor(mode) {
            switch(mode) {
                case "performance": return "#FFD700";
                case "power-saver": return "#90EE90";
                default: return "#ffffff"; 
            }
        }
    }

    // ============================================================
    // 布局与交互
    // ============================================================
    MouseArea {
        anchors.fill: parent
        enabled: !root.expanded
        cursorShape: Qt.PointingHandCursor
        onClicked: { getProc.running = true; root.expanded = true; }
    }

    Timer {
        id: autoCloseTimer
        interval: 3000; running: root.expanded
        onTriggered: root.expanded = false
    }

    Item {
        anchors.fill: parent
        clip: true 

        // 收起状态
        Text {
            anchors.centerIn: parent
            text: style.getIcon(root.currentProfile)
            color: style.getColor(root.currentProfile)
            font.family: Sizes.fontIcon
            font.pixelSize: 16 
            
            visible: !root.expanded
            opacity: root.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // 展开状态
        RowLayout {
            anchors.centerIn: parent
            
            // 【修改点 2】增大图标间距
            // 从 8 改为 15，视觉上图标更分散，更容易点击
            spacing: 15 
            
            opacity: root.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Text {
                text: ""
                color: root.currentProfile === "power-saver" ? "#90EE90" : "#555"
                font.family: "Symbols Nerd Font"; font.pixelSize: 16
                MouseArea { anchors.fill: parent; onClicked: { autoCloseTimer.restart(); root.setProfile("power-saver") } }
            }
            Text {
                text: ""
                color: root.currentProfile === "balanced" ? "#ffffff" : "#555"
                font.family: "Symbols Nerd Font"; font.pixelSize: 16
                MouseArea { anchors.fill: parent; onClicked: { autoCloseTimer.restart(); root.setProfile("balanced") } }
            }
            Text {
                text: "󱐋"
                color: root.currentProfile === "performance" ? "#FFD700" : "#555"
                font.family: "Symbols Nerd Font"; font.pixelSize: 16
                MouseArea { anchors.fill: parent; onClicked: { autoCloseTimer.restart(); root.setProfile("performance") } }
            }
        }
    }
}
