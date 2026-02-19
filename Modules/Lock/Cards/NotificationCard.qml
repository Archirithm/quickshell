import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config 

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    color: Colorsheme.surface_container
    radius: Sizes.lockCardRadius
    clip: true

    // ================== 界面布局 ==================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Text {
                text: "Notifications"
                color: Colorsheme.on_surface_variant
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.bold: true
            }
            
            // 计数器
            Rectangle {
                visible: NotificationStore.model.count > 0
                width: countText.contentWidth + 12
                height: 18
                radius: 9
                color: Colorsheme.primary_container
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: NotificationStore.model.count
                    color: Colorsheme.on_primary_container
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 10
                    font.bold: true
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // 清除按钮
            Text {
                text: "Clear All"
                visible: NotificationStore.model.count > 0
                color: Colorsheme.primary
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 12
                font.underline: true
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationStore.clear()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 1
            color: Colorsheme.outline; opacity: 0.2
        }

        // 通知列表
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 12
            
            model: NotificationStore.model

            // 空状态提示
            Text {
                anchors.centerIn: parent
                visible: NotificationStore.model.count === 0
                text: "No new notifications"
                color: Colorsheme.on_surface_variant
                font.family: Sizes.fontFamily
                font.pixelSize: 14
                opacity: 0.5
            }

            delegate: Rectangle {
                width: ListView.view.width
                height: 60
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    // 1. 图标容器
                    Rectangle {
                        width: 40; height: 40; radius: 12
                        color: Colorsheme.surface_container_highest
                        
                        // A. 图片图标 (如果有)
                        Image {
                            id: iconImg
                            anchors.fill: parent
                            anchors.margins: 6
                            source: model.imagePath
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready && model.imagePath !== ""
                            smooth: true
                        }
                        
                        // B. 默认气泡图标 (无图时显示)
                        // 【修改】这里不再显示首字母，而是显示气泡图标
                        Text {
                            anchors.centerIn: parent
                            text: "\uf0e5" // FontAwesome Comment-alt 图标
                            visible: !iconImg.visible
                            color: Colorsheme.on_surface_variant
                            // 这里要确保用支持图标的字体，通常 Nerd Font 兼容 FontAwesome
                            font.family: "Font Awesome 6 Free Solid" 
                            // 如果你的环境里主要是 Nerd Font，也可以试用 "JetBrainsMono Nerd Font"
                            // font.family: Sizes.fontFamilyMono 
                            font.pixelSize: 18
                        }
                    }

                    // 2. 文字内容
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: model.appName
                                color: Colorsheme.primary
                                font.family: Sizes.fontFamilyMono
                                font.pixelSize: 10
                                font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: model.time
                                color: Colorsheme.on_surface_variant
                                font.family: Sizes.fontFamilyMono
                                font.pixelSize: 10
                                opacity: 0.7
                            }
                        }

                        Text {
                            text: model.summary
                            color: Colorsheme.on_surface
                            font.family: Sizes.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        
                        Text {
                            text: model.body
                            color: Colorsheme.on_surface_variant
                            font.family: Sizes.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            opacity: 0.8
                        }
                    }
                    
                    // 单条删除
                    Text {
                        text: "×"
                        color: Colorsheme.on_surface_variant
                        font.pixelSize: 18
                        MouseArea {
                            anchors.fill: parent
                            onClicked: NotificationStore.remove(index)
                        }
                    }
                }
            }
            
            // 动画效果
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                NumberAnimation { property: "y"; from: -20; duration: 200 }
            }
            remove: Transition {
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                NumberAnimation { property: "height"; to: 0; duration: 200 }
            }
        }
    }
}
