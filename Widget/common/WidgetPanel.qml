import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root
    property string title: ""
    property string icon: ""
    property alias headerTools: headerToolsLayout.data 
    default property alias content: contentLayout.data
    property var closeAction: () => {} 

    Theme { id: theme }
    
    // 【核心修复】：剥离背景色与边框，让底部固定的液态遮罩透出来！
    color: "transparent"
    border.color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.padding
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text { text: root.icon; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20; color: theme.primary }
            Text { text: root.title; font.bold: true; font.pixelSize: 18; color: theme.text; Layout.fillWidth: true; Layout.leftMargin: 10 }
            
            RowLayout { id: headerToolsLayout; spacing: 12 }
            
            Item { width: 12 }
            
            Text {
                text: "\uf00d"
                font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18; color: theme.subtext
                MouseArea { 
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.closeAction()
                }
            }
        }

        ColumnLayout {
            id: contentLayout
            Layout.fillWidth: true; Layout.fillHeight: true
        }
    }
}
