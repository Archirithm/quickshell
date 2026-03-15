import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Services
import qs.config
import qs.Widget

Rectangle {
    id: root
    
    property bool isHovered: mouseArea.containsMouse
    
    // 内部小圆高度为 28
    implicitHeight: 28
    implicitWidth: isHovered ? (layout.width + 20) : 28
    radius: height / 2 
    
    // 赋予独立的主题背景色
    color: Colorscheme.primary_container 

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    NetworkWidget { id: wifiPanel; isOpen: false }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6
        width: isHovered ? implicitWidth : iconText.implicitWidth

        Text {
            id: iconText
            font.family: "JetBrainsMono Nerd Font" 
            font.pixelSize: 14 // 适配缩小后的按钮
            Layout.alignment: Qt.AlignVCenter
            
            // 图标颜色使用容器对应的前景色
            color: Colorscheme.on_primary_container 
            
            text: {
                if (Network.activeConnectionType === "ETHERNET") return "󰈀"; 
                if (!Network.connected) return "󰤭"; 
                let strength = Network.signalStrength; 
                if (strength >= 80) return "󰤨";
                if (strength >= 60) return "󰤥";
                if (strength >= 40) return "󰤢";
                if (strength >= 20) return "󰤟";
                return "󰤯"; 
            }
        }

        Text {
            id: nameText
            text: Network.activeConnection 
            font.bold: true 
            font.pixelSize: 12 
            color: Colorscheme.on_primary_container 
            Layout.alignment: Qt.AlignVCenter
            
            visible: root.isHovered
            opacity: root.isHovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor 
        onClicked: wifiPanel.isOpen = !wifiPanel.isOpen 
    }
}
