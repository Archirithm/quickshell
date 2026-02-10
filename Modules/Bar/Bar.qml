import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Modules.Bar.Workspaces
import qs.Modules.Bar.Clock
import qs.Modules.Bar.Tray
import qs.Modules.Bar.Cava
import qs.Modules.Bar.Network
import qs.Modules.Bar.Volume
import qs.Modules.Bar.PowerButton
import qs.Modules.Bar.PowerProfile
import qs.Modules.Bar.SysMonitor
import qs.Modules.Bar.NotificationButton
import qs.Modules.Bar.DayNightSwitch
import qs.Modules.DynamicIsland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData

        anchors { left: true; top: true; right: true }
        color: "transparent"
        
        property real barHeight: 52
        
        implicitHeight: Math.max(barWindow.barHeight, island.height + island.anchors.topMargin + 5)
        
        exclusiveZone: barHeight
        
        WlrLayershell.layer: WlrLayer.Top

        // ============================================================
        // 动态控制键盘焦点 (灵动岛展开时截获输入)
        // ============================================================
        WlrLayershell.keyboardFocus: (island.showLauncher || island.showWallpaper || island.showDashboard)
            ? WlrKeyboardFocus.Exclusive 
            : WlrKeyboardFocus.None

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
                Cava {}
                DayNightSwitch {}
            }

            // --- 中间：灵动岛 ---
            DynamicIsland {
                id: island  
                
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                
            }

            // --- 右侧组件 ---
            // ... 上面的代码保持不变 ...

            // --- 右侧组件 ---
            RowLayout {
                // 钉在右边
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 10
                
                // 【恢复自然顺序】
                // 1. 托盘

                SysMonitor {
                    Layout.alignment: Qt.AlignVCenter
                }

                Tray {}
                
                // 4. 电源模式胶囊
                // 因为我们在 PowerProfile.qml 里加了 implicitWidth: width
                // 所以当它动画变宽时，Layout 会实时把左边的组件（Volume, Network...）往左推
                PowerProfile {
                    Layout.alignment: Qt.AlignVCenter
                } 
                
                // 2. 网络
                Network {}
                
                // 3. 音量
                Volume {}


                
                
                NotificationButton {
                    Layout.alignment: Qt.AlignVCenter
                }

                // 5. 电源按钮 (在最右边，因为 Layout 锚定在右边，所以它位置不动)
                PowerButton {}
            }
        }
    }
}
