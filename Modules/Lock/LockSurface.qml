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
    [cite_start]readonly property real iconSize: 160  [cite: 256]

    // ================= 2. 背景处理 =================
    Rectangle {
        anchors.fill: parent
        color: "black" 
        z: -1
    [cite_start]} [cite: 256, 257]

    Image {
        id: wallpaper
        anchors.fill: parent
        z: 0
        // 【已修改】壁纸路径
        [cite_start]source: "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_rofi/current" [cite: 257]
        fillMode: Image.PreserveAspectCrop
        visible: false 
    }
    
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 64
        blur: 1.0
    [cite_start]} [cite: 257, 258]

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
    [cite_start]} [cite: 258, 259]

    // ================= 3. 入场动画 =================
    SequentialAnimation {
        id: startupAnim
        running: true 
        
        [cite_start]PauseAnimation { duration: 100 } [cite: 259]

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
                [cite_start]to: 360 [cite: 259, 260, 261]
                duration: 800
                easing.type: Easing.InOutBack
            }
        }
    [cite_start]} [cite: 261, 262]

    // ================= 4. 形变容器 =================
    Rectangle {
        id: morphContainer
        anchors.centerIn: parent
        clip: true 
        [cite_start]z: 1  [cite: 262, 263]
        
        width: iconSize + (root.targetWidth - iconSize) * root.animProgress
        height: iconSize + (root.targetHeight - iconSize) * root.animProgress
        
        radius: 30
        color: Colorscheme.surface 
        
        // A. 锁图标
        [cite_start]Item { [cite: 263, 264]
            id: lockIconContainer
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            
            opacity: 1 - root.animProgress
            [cite_start]scale: 1 - (0.5 * root.animProgress) [cite: 264]
            visible: opacity > 0

            Image {
                id: lockIconSource
                // 【已修改】锁图标路径
                [cite_start]source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/icons/lock.svg" [cite: 265]
                anchors.fill: parent
                [cite_start]fillMode: Image.PreserveAspectFit [cite: 265]
                visible: false 
                sourceSize.width: 512
                sourceSize.height: 512
            [cite_start]} [cite: 265, 266]

            MultiEffect {
                anchors.fill: lockIconSource
                [cite_start]source: lockIconSource [cite: 266]
                colorization: 1.0 
                colorizationColor: Colorscheme.on_surface 
                brightness: 1.0
            }
        [cite_start]} [cite: 266, 267]

        // B. 主内容
        [cite_start]Item { [cite: 267, 268]
            id: mainContent
            anchors.fill: parent
            
            opacity: root.animProgress > 0.5 ? (root.animProgress - 0.5) * 2 : 0
            scale: 0.8 + (0.2 * root.animProgress)
            [cite_start]visible: opacity > 0 [cite: 268, 269]

            RowLayout {
                anchors.fill: parent
                [cite_start]anchors.margins: 40  [cite: 269]
                spacing: 30

                // [左列]
                ColumnLayout {
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignVCenter
                    [cite_start]spacing: 20 [cite: 269, 270, 271]
                    
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/WeatherCard.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/MottoCard.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 160; source: "./Cards/MediaCard.qml" }
                [cite_start]} [cite: 271, 272, 273, 274]

                // [中列]
                ColumnLayout {
                    Layout.fillWidth: true
                    [cite_start]Layout.fillHeight: true [cite: 274]
                    Layout.alignment: Qt.AlignVCenter
                    [cite_start]spacing: 40 [cite: 274, 275]

                    // 时间
                    [cite_start]ColumnLayout { [cite: 275]
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 0
                        Text {
                            [cite_start]id: timeText [cite: 275, 276]
                            text: Qt.formatTime(new Date(), "HH:mm")
                            color: Colorscheme.primary
                            [cite_start]font.family: Sizes.fontFamilyMono [cite: 276, 277]
                            font.pixelSize: 96
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        [cite_start]} [cite: 277, 278]
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                            [cite_start]color: Colorscheme.on_surface_variant [cite: 278, 279]
                            font.family: Sizes.fontFamilyMono
                            font.pixelSize: 18
                            font.bold: true
                            [cite_start]Layout.alignment: Qt.AlignHCenter [cite: 279, 280]
                        }
                        Timer { interval: 1000; running: true; repeat: true; onTriggered: timeText.text = Qt.formatTime(new Date(), "HH:mm") }
                    [cite_start]} [cite: 280, 281, 282]

                    // 头像 (使用 Rectangle 裁剪 + OpacityMask)
                    [cite_start]Item { [cite: 282]
                        Layout.preferredWidth: 180; Layout.preferredHeight: 180
                        [cite_start]Layout.alignment: Qt.AlignHCenter [cite: 282, 283]
                        
                        [cite_start]Image { [cite: 283]
                            id: avatarImg
                            anchors.fill: parent
                            // 【已修改】头像路径
                            [cite_start]source: "file://" + Quickshell.env("HOME") + "/Pictures/avatar/shelby.jpg" [cite: 284]
                            [cite_start]sourceSize: Qt.size(180, 180) [cite: 284]
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                            [cite_start]cache: true [cite: 284, 285]
                        }
                        Rectangle {
                            id: mask
                            [cite_start]anchors.fill: parent [cite: 285, 286]
                            radius: 90
                            visible: false
                            [cite_start]color: "black" [cite: 286, 287]
                        }
                        OpacityMask {
                            anchors.fill: parent
                            [cite_start]source: avatarImg [cite: 287, 288]
                            maskSource: mask
                        }
                        Rectangle {
                            [cite_start]anchors.fill: parent [cite: 288, 289]
                            radius: 90
                            color: "transparent"
                            [cite_start]border.color: Colorscheme.outline [cite: 289, 290]
                            border.width: 4
                        }
                    [cite_start]} [cite: 290, 291]

                    // 密码输入
                    [cite_start]Loader { [cite: 291]
                        id: termLoader
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 50
                        [cite_start]Layout.alignment: Qt.AlignHCenter [cite: 291, 292]
                        [cite_start]source: "./Cards/AuthCard.qml" [cite: 292, 293]
                        
                        // 【强制注入】
                        [cite_start]onLoaded: { [cite: 293]
                            if (item) {
                                item.context = root.context
                            [cite_start]} [cite: 293, 294]
                        [cite_start]} [cite: 294, 295]
                        
                        // 【双重保险】Binding 绑定
                        [cite_start]Binding {  [cite: 295]
                            target: termLoader.item
                            property: "context"
                            value: root.context
                            [cite_start]when: termLoader.item !== null [cite: 295, 296]
                        }
                    }
                [cite_start]} [cite: 296, 297]

                // [右列]
                [cite_start]ColumnLayout { [cite: 297]
                    Layout.preferredWidth: 320
                    Layout.alignment: Qt.AlignVCenter
                    [cite_start]spacing: 20 [cite: 297, 298]
                    
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 280; source: "./Cards/SystemGrid.qml" }
                    Loader { Layout.fillWidth: true; Layout.preferredHeight: 220; source: "./Cards/NotificationCard.qml" }
                [cite_start]} [cite: 298, 299, 300]
            }
        }
    }

    // ================= 5. 焦点修复 (暴力模式) =================
    // 【核心修复 2】暴力定时器，确保焦点一定在输入框上
    Timer {
        interval: 100 
        running: root.animProgress === 1 // 仅在动画结束后运行
        [cite_start]repeat: true [cite: 300]
    
        onTriggered: {
            // 只要焦点不在输入框，就抢回来
            if (termLoader.item && !termLoader.item.activeFocus) {
                termLoader.item.forceActiveFocus()
            }
        }
    }
[cite_start]} [cite: 300, 301]
