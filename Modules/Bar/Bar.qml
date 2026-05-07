import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Modules.Bar.Workspaces
import qs.Modules.Bar.ActiveWindow
import qs.Modules.Bar.Tray
import qs.Modules.Bar.PowerButton
import qs.Modules.Bar.SysMonitor
import qs.Modules.Bar.QuickSettings
import qs.Common

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData

        anchors { left: true; top: true; right: true }
        color: "transparent"
        
        property real barHeight: Sizes.barHeight
        
        // 高度不再受灵动岛影响
        implicitHeight: barWindow.barHeight
        
        exclusiveZone: barHeight
        
        WlrLayershell.layer: WlrLayer.Top

        function inputRect(item) {
            if (!item || item.width <= 0 || item.height <= 0)
                return { "x": 0, "y": 0, "w": 0, "h": 0 };

            const pos = item.mapToItem(barWindow.contentItem, 0, 0);
            return {
                "x": Math.round(pos.x),
                "y": Math.round(pos.y),
                "w": Math.ceil(item.width),
                "h": Math.ceil(item.height)
            };
        }

        mask: Region {
            Region {
                readonly property var r: barWindow.inputRect(leftSection)
                x: r.x
                y: r.y
                width: r.w
                height: r.h
            }

            Region {
                readonly property var r: barWindow.inputRect(rightSection)
                x: r.x
                y: r.y
                width: r.w
                height: r.h
            }
        }

        // --- 内容容器 ---
        Item {
            id: barContent
            
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: barWindow.barHeight 

            // --- 左侧组件 ---
            RowLayout {
                id: leftSection
                anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom }
                width: implicitWidth
                height: implicitHeight
                spacing: 10

                Workspaces { screenName: barWindow.screen.name }
                SidebarButton {}
                ActiveWindow {}
                
            }

            // --- 右侧组件 ---
            RowLayout {
                id: rightSection
                anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom }
                width: implicitWidth
                height: implicitHeight
                spacing: 10

                Tray {}
                SysMonitor { Layout.alignment: Qt.AlignVCenter }
                

                QuickSettings { Layout.alignment: Qt.AlignVCenter }
                
                
            }
        }
    }
}
