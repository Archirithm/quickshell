import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.Modules.DynamicIsland.OverviewContent 

Item {
    id: root
    required property var manager

    visible: !ControlBackend.dndEnabled && manager.hasNotifs

    ListView {
        anchors.fill: parent
        model: root.manager.model
        spacing: 10
        clip: true
        interactive: false 

        delegate: Rectangle {
            id: delegateRoot
            width: ListView.view.width
            height: 60
            color: "transparent"

            // ============================================================
            // 【核心修复 4】：每条消息自带独立的心脏起搏器，时间一到，精准呼叫后端销毁自己
            // ============================================================
            Timer {
                interval: 5000
                running: true
                onTriggered: root.manager.removeByNotifId(model.notifId)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // 手动点击也走 ID 销毁通道
                onClicked: root.manager.removeByNotifId(model.notifId)
            }

            RowLayout {
                anchors.fill: parent
                anchors.bottomMargin: 4 
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    radius: 10
                    color: Colorscheme.background
                    clip: true 

                    property bool isIconName: model.imagePath !== undefined && model.imagePath.startsWith("icon:")
                    property string cleanPath: isIconName ? model.imagePath.substring(5) : (model.imagePath !== undefined ? model.imagePath : "")

                    Image {
                        anchors.fill: parent
                        source: parent.isIconName ? ("image://icon/" + parent.cleanPath) : parent.cleanPath
                        fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                        anchors.margins: parent.isIconName ? 6 : 0
                        asynchronous: true
                        
                        onStatusChanged: {
                            if (status === Image.Error) {
                                fallbackIcon.visible = true
                                visible = false
                            }
                        }
                    }

                    Text {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        text: "💬"
                        visible: parent.cleanPath === "" 
                        font.pixelSize: 20
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 2
                    Text {
                        text: model.summary !== undefined ? model.summary : ""
                        color: "white"; font.bold: true; font.pixelSize: 14
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    Text {
                        text: model.body !== undefined ? model.body : ""
                        color: "#aaa"; font.pixelSize: 12
                        Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2
                    }
                }
                
                Text {
                    text: "×"; color: "#444"; font.pixelSize: 18
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter 
                height: 2
                radius: 1
                color: Colorscheme.primary
                
                NumberAnimation on width {
                    from: delegateRoot.width - 20 
                    to: 0
                    duration: 5000 
                }
            }
        }
    }
}
