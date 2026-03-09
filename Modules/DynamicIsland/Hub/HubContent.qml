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
    
    // =======================================
    // 【核心修复】：动态宽度引擎
    // 只有在 Overview (带课表) 时展开为 880 宽屏，其他保持 760
    // =======================================
    implicitWidth: currentIndex === 0 ? 860 : 
                   currentIndex === 2 ? 960 : // 为壁纸界面分配 960 的超宽尺寸
                   760
    Behavior on implicitWidth { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    
    // =======================================
    // 动态高度引擎
    // =======================================
    implicitHeight: 80 + 20 + (
        currentIndex === 0 ? 520 : // Overview
        currentIndex === 1 ? 480 : // Media
        currentIndex === 2 ? 300 : // Wallpaper: 增加到 300 以容纳放大后的图片
        540                        // Weather (默认)
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

        // 模块定义
        TabBtn { icon: ""; title: "Overview"; index: 0 }
        TabBtn { icon: ""; title: "Media"; index: 1 }
        TabBtn { icon: ""; title: "Wallpapers"; index: 2 }
        TabBtn { icon: ""; title: "Weather"; index: 3 }
    }

    // =======================================
    // 内容渲染区
    // =======================================
    Item {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10 

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
            width: parent.width * 0.95 // 让它随父组件动态变宽
            height: 300
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
