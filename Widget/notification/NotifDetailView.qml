import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.Widget.common
import "../../JS/TimeUtils.js" as TimeUtils

Item {
    id: root
    Theme { id: theme }

    property string appId: ""
    property var filteredMessages: []
    
    // MD3 悬浮菜单展开状态
    property bool menuExpanded: false

    // ============================================================
    // 【终极状态重置保险】：监听页面的显示与隐藏！
    // 只要离开这个页面，立刻强制收起菜单，告别遗留状态 Bug！
    // ============================================================
    onVisibleChanged: {
        if (!visible) {
            menuExpanded = false;
        }
    }

    onAppIdChanged: {
        update();
        menuExpanded = false; 
    }

    function update() { 
        var msgs = WidgetState.notifMessages[root.appId];
        filteredMessages = msgs ? msgs : []; 
    }

    // 筛选出其他有消息的应用，用于生成悬浮菜单
    property var otherApps: {
        var ids = [];
        for (var id in WidgetState.notifAppCounts) {
            if (WidgetState.notifAppCounts[id] > 0 && id !== root.appId) {
                ids.push(id);
            }
        }
        return ids;
    }

    // 绝对悬浮，不挤占消息空间
    readonly property int realMessageHeight: Math.max(0, notifList.contentHeight - 72)
    readonly property int totalHeight: realMessageHeight > 0 ? Math.max(240, realMessageHeight + 40) : 240

    property int timeRefreshTrigger: 0
    Connections {
        target: WidgetState
        function onNotifOpenChanged() {
            if (WidgetState.notifOpen) root.timeRefreshTrigger += 1;
            if (!WidgetState.notifOpen) root.menuExpanded = false; 
        }
    }

    function getAppIconSource(id) { return id === "system" ? "" : "file:///home/archirithm/.config/quickshell/assets/apps/" + id + ".svg"; }
    function getAppName(id) { var names = { "system": "系统消息", "qq": "QQ", "wechat": "微信", "telegram": "Telegram", "discord": "Discord" }; return names[id] || "未知应用"; }

    function getNerdIcon(id) {
        switch(id) {
            case "qq": return "\uf1d6";       
            case "wechat": return "\uf1d7";   
            case "telegram": return "\uf2c6"; 
            case "discord": return "\uf392";  
            case "system": return "\uf013";   
            default: return "\uf2d6";         
        }
    }

    ListView {
        id: notifList
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 0   
        anchors.rightMargin: 10
        clip: true; spacing: 10
        model: root.filteredMessages

        // 统一底部透明缓冲垫 (72px)
        footer: Item { width: ListView.view ? ListView.view.width : 0; height: 72 }

        delegate: Rectangle {
            id: messageCard
            width: ListView.view.width
            color: theme.surface 
            radius: theme.radius
            
            property bool expanded: false
            
            implicitHeight: contentColumn.implicitHeight + theme.padding * 2
            Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

            MouseArea { anchors.fill: parent; onClicked: expanded = !expanded }

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: theme.padding
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    
                    Image { source: getAppIconSource(root.appId); visible: root.appId !== "system"; Layout.preferredWidth: 16; Layout.preferredHeight: 16; sourceSize: Qt.size(16, 16) }
                    Text { text: "\uf0f3"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 14; color: theme.primary; visible: root.appId === "system" }
                    
                    Text { text: modelData.title; font.bold: true; font.pixelSize: 14; color: theme.text; elide: Text.ElideRight; Layout.fillWidth: true }
                    
                    Text { 
                        text: { var trigger = root.timeRefreshTrigger; return TimeUtils.getRelativeTime(modelData.timestamp); }
                        font.pixelSize: 12; color: theme.subtext 
                    }
                    
                    Text {
                        text: "\uf00d" 
                        font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 14; color: theme.subtext; opacity: 0.6
                        MouseArea { 
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onEntered: parent.opacity = 1; onExited: parent.opacity = 0.6
                            onClicked: root.dismissMessage(modelData.id) 
                        }
                    }
                }
                
                Text {
                    text: modelData.body
                    font.pixelSize: 13; color: theme.subtext; 
                    elide: Text.ElideRight; wrapMode: Text.Wrap
                    maximumLineCount: expanded ? 99 : 1
                    Layout.fillWidth: true
                }
            }
            
            DragHandler {
                id: dragHandler; target: parent; xAxis.enabled: true; yAxis.enabled: false
                onActiveChanged: { if (!active) { if (Math.abs(parent.x) > 60) { root.dismissMessage(modelData.id) } else { snapBackAnimation.start() } } }
            }
            x: dragHandler.active ? dragHandler.translation.x : 0
            NumberAnimation on x { id: snapBackAnimation; to: 0; duration: 250; running: false; easing.type: Easing.OutQuint }
        }
    }

    // ============================================================
    // 【精致版 MD3 悬浮指示器与菜单】
    // ============================================================
    Item {
        id: fabContainer
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 32 
        anchors.rightMargin: 16 
        
        width: splitRow.width
        height: splitRow.height
        z: 100

        // 1. 弹出菜单
        Rectangle {
            id: popupMenu
            width: 150
            height: menuColumn.implicitHeight + 12
            radius: 12
            color: Colorscheme.surface_container_highest
            
            anchors.bottom: splitRow.top
            anchors.right: splitRow.right
            anchors.bottomMargin: 8
            
            opacity: root.menuExpanded ? 1.0 : 0.0
            scale: root.menuExpanded ? 1.0 : 0.8
            transformOrigin: Item.BottomRight
            visible: opacity > 0
            
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }

            Column {
                id: menuColumn
                anchors.centerIn: parent
                width: parent.width - 12
                spacing: 4

                Rectangle {
                    width: parent.width; height: 36; radius: 6
                    color: backHover.containsMouse ? Colorscheme.surface_variant : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 8
                        Text { text: "\uf060"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 13; color: theme.text }
                        Text { text: "返回总览"; font.bold: true; font.pixelSize: 13; color: theme.text; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: backHover
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            WidgetState.notifCurrentView = "main";
                            root.menuExpanded = false; // 双重保险：点击返回立刻重置
                        }
                    }
                }

                Repeater {
                    model: root.otherApps
                    delegate: Rectangle {
                        width: parent.width; height: 36; radius: 6
                        color: appItemHover.containsMouse ? Colorscheme.surface_variant : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 8
                            Text { text: getNerdIcon(modelData); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: theme.text }
                            Text { text: getAppName(modelData); font.bold: true; font.pixelSize: 13; color: theme.text; Layout.fillWidth: true }
                            
                            Rectangle {
                                width: 18; height: 18; radius: 9; color: theme.primary
                                Text { anchors.centerIn: parent; text: WidgetState.notifAppCounts[modelData]; font.pixelSize: 10; font.bold: true; color: Colorscheme.on_primary }
                            }
                        }
                        MouseArea {
                            id: appItemHover
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                WidgetState.notifDetailAppId = modelData;
                                root.menuExpanded = false;
                            }
                        }
                    }
                }
            }
        }

        // 2. 长条椭圆胶囊体 (40px 高度版)
        Row {
            id: splitRow
            spacing: 2 
            
            Item {
                width: leftContent.implicitWidth + 32 
                height: 40 
                
                Rectangle {
                    width: 40; height: 40
                    anchors.left: parent.left
                    radius: 20
                    color: theme.primary
                }
                
                Rectangle {
                    width: 16; height: 40
                    anchors.right: parent.right
                    radius: 8
                    color: theme.primary
                }
                
                Rectangle {
                    anchors.left: parent.left; anchors.leftMargin: 20
                    anchors.right: parent.right; anchors.rightMargin: 8
                    height: 40
                    color: theme.primary
                }

                RowLayout {
                    id: leftContent
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: getNerdIcon(root.appId); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: Colorscheme.on_primary }
                    Text { text: getAppName(root.appId); font.bold: true; font.pixelSize: 15; color: Colorscheme.on_primary }
                }
            }

            Item {
                width: 40 
                height: 40
                
                Rectangle {
                    anchors.fill: parent
                    radius: 20
                    color: theme.primary
                }
                
                Item {
                    width: 20; height: 40
                    anchors.left: parent.left
                    opacity: root.menuExpanded ? 0.0 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    Rectangle {
                        width: 16; height: 40
                        anchors.left: parent.left
                        radius: 8
                        color: theme.primary
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right
                        height: 40
                        color: theme.primary
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.menuExpanded ? "\uf077" : "\uf078" 
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 14 
                    color: Colorscheme.on_primary
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuExpanded = !root.menuExpanded
                }
            }
        }
    }

    function dismissMessage(messageId) { WidgetState.dismissMessage(appId, messageId); }
}
