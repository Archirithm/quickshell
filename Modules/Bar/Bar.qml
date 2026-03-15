import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Modules.Bar.Workspaces
import qs.Modules.Bar.Clock
import qs.Modules.Bar.Tray
// import qs.Modules.Bar.Cava
import qs.Modules.Bar.Network
import qs.Modules.Bar.Volume
import qs.Modules.Bar.PowerButton
// import qs.Modules.Bar.PowerProfile
import qs.Modules.Bar.SysMonitor
import qs.Modules.Bar.NotificationButton
import qs.Modules.Bar.QuickSettings
// import qs.Modules.Bar.DayNightSwitch
// 删除了对 DynamicIsland 的引入

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData

        anchors { left: true; top: true; right: true }
        color: "transparent"
        
        property real barHeight: 52
        
        // 高度不再受灵动岛影响
        implicitHeight: barWindow.barHeight
        
        exclusiveZone: barHeight
        
        WlrLayershell.layer: WlrLayer.Top

        // --- 内容容器 ---
        Item {
            id: barContent
            
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: barWindow.barHeight 

            // --- 左侧组件 ---
            RowLayout {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 10
                Workspaces {}
                // Cava {}
                // DayNightSwitch {}
            }

            // --- 右侧组件 ---
            RowLayout {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 10

                Tray {}
                SysMonitor { Layout.alignment: Qt.AlignVCenter }
                

                QuickSettings { Layout.alignment: Qt.AlignVCenter }
                
                // PowerProfile { Layout.alignment: Qt.AlignVCenter } 
                // Network {}
                // Volume {}
                //
                // NotificationButton { Layout.alignment: Qt.AlignVCenter }
                // PowerButton {}
            }
        }
    }
}
