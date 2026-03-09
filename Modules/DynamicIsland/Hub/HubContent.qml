import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

import qs.Modules.DynamicIsland.OverviewContent
import qs.Modules.DynamicIsland.Media
import qs.Modules.DynamicIsland.WallpaperContent
import qs.Modules.DynamicIsland.WeatherContent

Item {
    id: root
    signal closeRequested()
    
    property var player: null
    property int currentIndex: 0
    
    // 宽度稍微大于 720，留出呼吸感边距
    implicitWidth: 760
    
    // 高度计算去掉了 Settings，只剩 4 个面板
    implicitHeight: 80 + 20 + (
        currentIndex === 0 ? 360 : // Overview
        currentIndex === 1 ? 480 : // Media
        currentIndex === 2 ? 260 : // Wallpaper
        540                        // Weather (最后的默认值)
    )

    Behavior on implicitHeight { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    // =======================================
    // 顶部 Tab Bar (强制吸顶)
    // =======================================
    RowLayout {
        id: tabBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        anchors.margins: 10
        spacing: 15

        component TabBtn : Item {
            property string icon: ""
            property string title: ""
            property int index: 0
            property bool active: root.currentIndex === index
            
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: parent.parent.icon
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 20
                    color: parent.parent.active ? "white" : "#888888"
                    anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: parent.parent.title
                    font.pixelSize: 13
                    font.bold: parent.parent.active
                    color: parent.parent.active ? "white" : "#888888"
                    anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
            
            // 底部的高亮指示条
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.active ? 40 : 0
                height: 3
                radius: 1.5
                color: "white" 
                opacity: parent.active ? 1.0 : 0.0
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentIndex = parent.index
            }
        }

        // 只保留 4 个模块
        TabBtn { icon: ""; title: "Overview"; index: 0 }
        TabBtn { icon: ""; title: "Media"; index: 1 }
        TabBtn { icon: ""; title: "Wallpapers"; index: 2 }
        TabBtn { icon: ""; title: "Weather"; index: 3 }
    }

    // =======================================
    // 内容渲染区 (强制固定在 tabBar 下方)
    // =======================================
    Item {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10 // 给 Tab栏 和 内容 之间一点呼吸空间

        OverviewContent {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.currentIndex === 0
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            onCloseRequested: root.closeRequested()
        }

        Media {
            player: root.player
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.currentIndex === 1
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        WallpaperContent {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 720
            height: 260
            visible: root.currentIndex === 2
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            onWallpaperChanged: root.closeRequested()
        }

        WeatherContent {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.currentIndex === 3
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
}
