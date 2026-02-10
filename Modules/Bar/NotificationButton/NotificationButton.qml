import QtQuick
import Quickshell
import qs.config
import qs.Widget

Rectangle {
    id: root

    // --- 样式设定 (完全仿照 PowerButton) ---
    color: Colorsheme.on_primary_container 
    
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    
    // 宽度自适应
    implicitWidth: icon.contentWidth + 20

    // --- 交互区域 ---
    NotificationWidget {
        id: notifPanel
        isOpen: false
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        // 3. 点击切换开关
        onClicked: {
            notifPanel.isOpen = !notifPanel.isOpen
        }
    }

    // --- 图标内容 ---
    Text {
        id: icon
        anchors.centerIn: parent
        
        // 铃铛图标 (Font Awesome)
        text: "\uf0f3" 
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 15
        font.bold: true
        
        color: Colorsheme.background 
    }
}
