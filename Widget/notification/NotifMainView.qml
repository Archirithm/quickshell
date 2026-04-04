// Widget/notification/NotifMainView.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.Widget.common
import QtQuick.Controls

Item {
    id: root

    Theme { id: theme }
    
    // 严格定义的每行高度和面板内部 Padding
    readonly property int itemHeight: 68
    readonly property int innerPadding: 12
    readonly property int totalHeight: notifRepeater.count === 0 ? 120 : (notifRepeater.count * itemHeight + innerPadding * 2)

    // 数据驱动逻辑：过滤出有通知的 App ID
    property var filteredAppIds: {
        var ids = [];
        for (var appId in WidgetState.notifAppCounts) {
            if (WidgetState.notifAppCounts[appId] > 0) ids.push(appId);
        }
        // 按照最新消息到达的时间戳进行降序排列 (最新的排最前)
        ids.sort(function(a, b) {
            var timeA = (WidgetState.notifMessages[a] && WidgetState.notifMessages[a].length > 0) ? (WidgetState.notifMessages[a][0].timestamp || 0) : 0;
            var timeB = (WidgetState.notifMessages[b] && WidgetState.notifMessages[b].length > 0) ? (WidgetState.notifMessages[b][0].timestamp || 0) : 0;
            return timeB - timeA; 
        });
        return ids;
    }

    function update() { notifRepeater.model = filteredAppIds; }
    function getAppIconSource(appId) { return appId === "system" ? "" : "file:///home/archirithm/.config/quickshell/assets/apps/" + appId + ".svg"; }
    function getAppName(appId) { var names = { "system": "系统消息", "qq": "QQ", "wechat": "微信", "telegram": "Telegram", "discord": "Discord" }; return names[appId] || "未知应用"; }
    function getAppBrandColor(appId) {
        switch(appId) {
            case "telegram": return "#2AABEE"; 
            case "discord": return "#5865F2";  
            case "wechat": return "#07C160";   
            case "qq": return "#FFB300";       
            case "system": return theme.primary;         
            default: return theme.surface_variant;
        }
    }

    Text {
        anchors.centerIn: parent
        visible: notifRepeater.count === 0
        text: "没有新通知"
        font.pixelSize: 16; font.bold: true; color: theme.subtext
    }

    // 主分类列表容器，直接悬浮在面板上，去掉独立的背景卡片
    Column {
        anchors.fill: parent
        anchors.margins: root.innerPadding
        spacing: 0
        visible: notifRepeater.count > 0

        Repeater {
            id: notifRepeater
            model: root.filteredAppIds

            delegate: Item {
                id: itemDelegate
                width: parent.width; height: root.itemHeight
                z: maHover.containsMouse ? 10 : 1
                property color brandColor: getAppBrandColor(modelData)

                Rectangle {
                    id: hoverBg
                    anchors.centerIn: parent
                    width: parent.width; height: parent.height; radius: 12
                    color: maHover.containsMouse ? Qt.rgba(brandColor.r, brandColor.g, brandColor.b, 0.15) : "transparent"
                    scale: maHover.containsMouse ? 1.04 : 1.0
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        // ============================================================
                        // 【细节优化】：大幅减小左右边距，将两端内容往外推，拉长中间距离！
                        // 呼吸感拉满。
                        // ============================================================
                        anchors.leftMargin: 6 
                        anchors.rightMargin: 6
                        anchors.topMargin: 14 
                        anchors.bottomMargin: 14
                        spacing: 16

                        Item {
                            Layout.preferredWidth: 36; Layout.preferredHeight: 36
                            Image { anchors.fill: parent; source: getAppIconSource(modelData); visible: modelData !== "system"; sourceSize: Qt.size(40, 40) }
                            Rectangle {
                                anchors.fill: parent; radius: 18; color: brandColor; visible: modelData === "system"
                                Text { anchors.centerIn: parent; text: "\uf0f3"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 16; color: Colorscheme.on_primary }
                            }
                        }

                        // 应用名称 (Layout.fillWidth 会自动拉伸占据中间空间)
                        Text { text: getAppName(modelData); font.bold: true; font.pixelSize: 15; color: theme.text; Layout.fillWidth: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            width: countText.implicitWidth + 24; height: 28; radius: 14; color: brandColor
                            Text {
                                id: countText; anchors.centerIn: parent; text: WidgetState.notifAppCounts[modelData] + " 条消息"
                                font.pixelSize: 13; font.bold: true; color: modelData === "system" ? Colorscheme.on_primary : "#FFFFFF"
                            }
                        }
                    }
                }

                MouseArea {
                    id: maHover
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { WidgetState.notifDetailAppId = modelData; WidgetState.notifCurrentView = "detail"; }
                }
            }
        }
    }
}
