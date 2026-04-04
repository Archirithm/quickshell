// Widget/notification/NotifAllView.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.Widget.common
import "../../JS/TimeUtils.js" as TimeUtils

Item {
    id: root
    Theme { id: theme }

    property var allMessages: WidgetState.getAllMessages()
    function update() { allMessages = WidgetState.getAllMessages(); }

    // 【核心同步 1】：统一高度计算公式
    readonly property int totalHeight: notifList.contentHeight > 0 ? notifList.contentHeight + 40 : 120

    // 时间强制刷新触发器
    property int timeRefreshTrigger: 0
    Connections {
        target: WidgetState
        function onNotifOpenChanged() {
            if (WidgetState.notifOpen) root.timeRefreshTrigger += 1;
        }
    }

    function getAppIconSource(appId) { return appId === "system" ? "" : "file:///home/archirithm/.config/quickshell/assets/apps/" + appId + ".svg"; }

    Text {
        anchors.centerIn: parent
        visible: allMessages.length === 0
        text: "没有新通知"
        font.pixelSize: 16; font.bold: true; color: theme.subtext
    }

    ListView {
        id: notifList
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.leftMargin: 0   
        anchors.rightMargin: 10
        clip: true; spacing: 10
        model: root.allMessages
        visible: allMessages.length > 0

        // 【核心同步 3】：统一底部透明缓冲垫，保证滑到底部时的留白完全一致
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
                    
                    Image { source: getAppIconSource(modelData.appId); visible: modelData.appId !== "system"; Layout.preferredWidth: 16; Layout.preferredHeight: 16; sourceSize: Qt.size(16, 16) }
                    Text { text: "\uf0f3"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 14; color: theme.primary; visible: modelData.appId === "system" }
                    
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
                            onClicked: WidgetState.dismissMessage(modelData.appId, modelData.id) 
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
                onActiveChanged: { if (!active) { if (Math.abs(parent.x) > 60) { WidgetState.dismissMessage(modelData.appId, modelData.id) } else { snapBackAnimation.start() } } }
            }
            x: dragHandler.active ? dragHandler.translation.x : 0
            NumberAnimation on x { id: snapBackAnimation; to: 0; duration: 250; running: false; easing.type: Easing.OutQuint }
        }
    }
}
