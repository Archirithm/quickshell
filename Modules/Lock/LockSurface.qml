import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects 
import Quickshell
import Quickshell.Wayland 

// 根节点保持 WlSessionLockSurface，这样结构最标准
WlSessionLockSurface {
    id: root
    required property var context

    // ================= 1. 状态与变量 =================
    property real animProgress: 0 
    
    readonly property real targetWidth: 1060
    readonly property real targetHeight: 600
    readonly property real iconSize: 160
    
    // ================= 2. 背景处理 (壁纸 + 模糊) =================
    
    // 保底背景
    Rectangle {
        anchors.fill: parent
        color: "black"
        z: -1
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        z: 0
        
        // 指向你的壁纸路径
        source: "file:///home/archirithm/.cache/wallpaper_rofi/current"
        
        fillMode: Image.PreserveAspectCrop
        
        // 开启模糊特效 (毛玻璃)
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 48    // 模糊半径
            blur: 1.0      // 强度
            
            
            autoPaddingEnabled: false
        }
    }

    // ================= 3. 核心入场动画 =================
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

    // ================= 4. 核心形变容器 (前景 UI) =================
    Rectangle {
        id: morphContainer
        anchors.centerIn: parent
        clip: true 
        z: 1 // 确保在背景之上
        
        // 动态计算尺寸
        width: iconSize + (root.targetWidth - iconSize) * root.animProgress
        height: iconSize + (root.targetHeight - iconSize) * root.animProgress
        
        radius: 24
        
        // 固定背景色透明度，实现丝滑过渡
        color: Qt.rgba(0, 0, 0, 0.4)

        // ---------------- A. 锁图标容器 ----------------
        Item {
            id: lockIconContainer
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            
            opacity: 1 - root.animProgress
            scale: 1 - (0.5 * root.animProgress)

            Image {
                id: lockIconSource
                source: "file:///home/archirithm/.config/quickshell/assets/icons/lock.svg"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: false 
                sourceSize.width: 160
                sourceSize.height: 160
            }

            MultiEffect {
                anchors.fill: lockIconSource
                source: lockIconSource
                
                // 强制图标变白
                colorization: 1.0 
                colorizationColor: "white"
                brightness: 1.0
            }
        }

        // ---------------- B. 卡片内容组 ----------------
        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 20
            
            opacity: root.animProgress > 0.5 ? (root.animProgress - 0.5) * 2 : 0
            scale: 0.8 + (0.2 * root.animProgress)
            visible: opacity > 0

            // --- 左侧列 ---
            ColumnLayout {
                spacing: 20
                Loader { 
                    source: "./Cards/AvatarCard.qml"
                    Layout.preferredWidth: 260; Layout.preferredHeight: 360
                }
                Loader {
                    source: "./Cards/MottoCard.qml"
                    Layout.preferredWidth: 260; Layout.preferredHeight: 160
                }
            }

            // --- 中间列 ---
            ColumnLayout {
                spacing: 20
                Loader {
                    source: "./Cards/SystemCard.qml"
                    Layout.preferredWidth: 420; Layout.preferredHeight: 110
                }
                Loader {
                    source: "./Cards/ClockCard.qml"
                    Layout.preferredWidth: 420; Layout.preferredHeight: 170
                }
                Loader {
                    source: "./Cards/WeatherCard.qml"
                    Layout.preferredWidth: 420; Layout.preferredHeight: 220
                }
            }

            // --- 右侧列 ---
            ColumnLayout {
                spacing: 20
                Loader {
                    source: "./Cards/MediaCard.qml"
                    Layout.preferredWidth: 280; Layout.preferredHeight: 260
                }
                Loader {
                    id: termLoader
                    source: "./Cards/TerminalCard.qml"
                    Layout.preferredWidth: 280; Layout.preferredHeight: 260
                    
                    onLoaded: {
                        if (item) item.context = root.context
                    }
                    
                    Connections {
                        target: root
                        function onAnimProgressChanged() {
                            if (root.animProgress === 1 && termLoader.item) {
                                termLoader.item.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }
    }
}
