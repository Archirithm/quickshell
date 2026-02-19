import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects 
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Wayland 
import qs.config

Item {
    id: root
    property var context: null

    anchors.fill: parent

    // ================= 1. 动画状态 =================
    property real animProgress: 0 
    
    readonly property real targetWidth: 1160
    readonly property real targetHeight: 600 
    readonly property real iconSize: 160 

    // ================= 2. 背景处理 =================
    Rectangle {
        anchors.fill: parent
        color: "black" 
        z: -1
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        z: 0
        source: "file:///home/archirithm/.cache/wallpaper_rofi/current"
        fillMode: Image.PreserveAspectCrop
        visible: false 
    }
    
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    }

    // 【核心修复 1】背景点击劫持
    // 只要你点击了背景空白处，立刻把焦点还给输入框
    MouseArea {
        anchors.fill: parent
        z: 0 // 在背景之上，内容之下
        onClicked: {
            if (termLoader.item) {
                termLoader.item.forceActiveFocus()
            }
        }
    }

    // ================= 3. 入场动画 =================
    SequentialAnimation {
        id: startupAnim
        running: true 
        
        PauseAnimation { duration: 100 }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "animProgress"
                to: 1
                duration: 800
                easing.type: Easing.InOutExpo 
            }
            NumberAnimation {
                target: lockIconContainer
                property: "rotation"
                from: 0
                to: 360
                duration: 800
                easing.type: Easing.InOutBack
            }
        }
    }

    // ================= 4. 形变容器 =================
    Rectangle {
        id: morphContainer
        anchors.centerIn: parent
        clip: true 
        z: 1 
        
        width: iconSize + (root.targetWidth - iconSize) * root.animProgress
        height: iconSize + (root.targetHeight - iconSize) * root.animProgress
        
        radius: 30
        color: Colorsheme.surface 
        
        // A. 锁图标
        Item {
            id: lockIconContainer
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            
            opacity: 1 - root.animProgress
            scale: 1 - (0.5 * root.animProgress)
            visible: opacity > 0

            Image {
                id: lockIconSource
                source: "file:///home/archirithm/.config/quickshell/assets/icons/lock.svg"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: false 
                sourceSize.width: 512
                sourceSize.height: 512
            }

            MultiEffect {
                anchors.fill: lockIconSource
                source: lockIconSource
                colorization: 1.0 
                colorizationColor: Colorsheme.on_surface 
                brightness: 1.0
            }
        }

        // B. 主内容
        Item {
            id: mainContent
            anchors.fill: parent
            
            opacity: root.animProgress > 0.5 ? (root.animProgress - 0.5) * 2 : 0
            scale: 0.8 + (0.2 * root.animProgress)
            visible: opacity > 0

            RowLayout {
                anchors.fill: parent
                anchors.margins: 40 
                spacing: 30

                // [左列]
                ColumnLayout {
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20
                    
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/WeatherCard.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/MottoCard.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/MediaCard.qml" }
                }

                // [中列]
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 40

                    // 时间
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0
                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "HH:mm")
                            color: Colorsheme.primary
                            font.family: Sizes.fontFamilyMono
                            font.pixelSize: 96
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                            color: Colorsheme.on_surface_variant
                            font.family: Sizes.fontFamilyMono
                            font.pixelSize: 18
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: timeText.text = Qt.formatTime(new Date(), "HH:mm") }
                    }

                    // 头像 (使用 Rectangle 裁剪 + OpacityMask)
                    Item {
                        Layout.preferredWidth: 180; Layout.preferredHeight: 180
                        Layout.alignment: Qt.AlignHCenter
                        
                        Image {
                            id: avatarImg
                            anchors.fill: parent
                            source: "file:///home/archirithm/Pictures/avatar/shelby.jpg"
                            sourceSize: Qt.size(180, 180)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            cache: true
                        }
                        Rectangle {
                            id: mask
                            anchors.fill: parent
                            radius: 90
                            visible: false
                            color: "black"
                        }
                        OpacityMask {
                            anchors.fill: parent
                            source: avatarImg
                            maskSource: mask
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 90
                            color: "transparent"
                            border.color: Colorsheme.outline
                            border.width: 4
                        }
                    }

                    // 密码输入
                    Loader {
                        id: termLoader
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 50
                        Layout.alignment: Qt.AlignHCenter
                        source: "./Cards/AuthCard.qml"
                        
                        // 【强制注入】
                        onLoaded: {
                            if (item) {
                                item.context = root.context
                            }
                        }
                        
                        // 【双重保险】Binding 绑定
                        Binding { 
                            target: termLoader.item
                            property: "context"
                            value: root.context
                            when: termLoader.item !== null
                        }
                    }
                }

                // [右列]
                ColumnLayout {
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 20
                    
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 280; source: "./Cards/SystemGrid.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 220; source: "./Cards/NotificationCard.qml" }
                }
            }
        }
    }

    // ================= 5. 焦点修复 (暴力模式) =================
    // 【核心修复 2】暴力定时器，确保焦点一定在输入框上
    Timer {
        interval: 100 
        running: root.animProgress === 1 // 仅在动画结束后运行
        repeat: true
        onTriggered: {
            // 只要焦点不在输入框，就抢回来
            if (termLoader.item && !termLoader.item.activeFocus) {
                termLoader.item.forceActiveFocus()
            }
        }
    }
}
