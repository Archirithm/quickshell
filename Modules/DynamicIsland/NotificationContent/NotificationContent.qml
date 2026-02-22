import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

Item {
    id: root
    required property var manager

    ListView {
        anchors.fill: parent
        model: root.manager.model
        spacing: 10
        clip: true
        interactive: false 

        delegate: Rectangle {
            width: ListView.view.width
            height: 60
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.manager.remove(index)
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 12

                // --- 图标/头像区域 ---
                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    radius: 10
                    color: Colorscheme.background
                    clip: true // 这一步很关键，切圆角

                    // 预处理路径
                    property bool isIconName: model.imagePath.startsWith("icon:")
                    // 如果是图标名，去掉前缀；如果是文件路径，保留原样
                    property string cleanPath: isIconName ? model.imagePath.substring(5) : model.imagePath

                    // 【核心修改】统一使用 Image 组件，利用 Quickshell 的 image://icon 协议
                    Image {
                        anchors.fill: parent
                        
                        // 逻辑：
                        // 1. 如果是 "icon:qq"，则加载 "image://icon/qq" (去系统里找图标)
                        // 2. 如果是 "file://..."，则直接加载文件 (显示好友头像)
                        source: parent.isIconName 
                                ? ("image://icon/" + parent.cleanPath) 
                                : parent.cleanPath

                        // 填充模式：
                        // 头像需要 Crop (裁切填满)，图标需要 Fit (完整显示)
                        fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                        
                        // 如果是图标，留一点边距比较好看；如果是头像，填满
                        anchors.margins: parent.isIconName ? 6 : 0

                        asynchronous: true
                        
                        // 错误处理：如果加载失败，显示默认气泡
                        onStatusChanged: {
                            if (status === Image.Error) {
                                fallbackIcon.visible = true
                                visible = false
                            }
                        }
                    }

                    // 兜底图标 (当图片加载失败或为空时显示)
                    Text {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        text: "💬"
                        visible: parent.cleanPath === "" // 默认不可见
                        font.pixelSize: 20
                    }
                }

                // --- 文字区域 (保持不变) ---
                ColumnLayout {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 2
                    Text {
                        text: model.summary; color: "white"; font.bold: true; font.pixelSize: 14
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    Text {
                        text: model.body; color: "#aaa"; font.pixelSize: 12
                        Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2
                    }
                }
                
                // 关闭按钮
                Text {
                    text: "×"; color: "#444"; font.pixelSize: 18
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
            }
        }
    }
}
