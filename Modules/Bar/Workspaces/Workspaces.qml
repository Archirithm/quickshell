import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.config
// import qs.Config // 已不再需要，因为颜色已写死

Rectangle {
    id: root

    // 【修改点 1】 原 Colorscheme.surface 替换为固定深色背景
    // 你可以修改这里改变整个条的背景色
    color: Colorscheme.background 
    
    radius: Sizes.cornerRadius
    implicitHeight: Sizes.barHeight
    implicitWidth: layout.width + 20

    property Item activeItem: null

    // --- 滑动的高亮块 ---
    Rectangle {
        id: indicator

        x: layout.x + (root.activeItem ? root.activeItem.x : 0)
        y: layout.y + (root.activeItem ? root.activeItem.y : 0)

        width: root.activeItem ? root.activeItem.width : 0
        height: 26

        radius: 14

        // 之前修改的高亮色
        color: Colorscheme.on_primary_container

        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: Niri.workspaces

            delegate: Item {
                id: delegateRoot

                property bool active: model.isActive

                implicitWidth: active ? (numText.implicitWidth + 24) : (numText.implicitWidth + 12)
                implicitHeight: 26

                onActiveChanged: { if (active) root.activeItem = delegateRoot }
                Component.onCompleted: { if (active) root.activeItem = delegateRoot }

                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    // 保持 index 逻辑，防止乱跳
                    onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", model.idx.toString()])
                }

                Text {
                    id: numText

                    anchors.centerIn: parent
                    text: model.idx
                    font.bold: true
                    font.pixelSize: 14

                    // 【修改点 2】 
                    // 选中状态：黑色 ("#000000") - 为了配合亮色的高亮块
                    // 未选中状态：白色 ("#ffffff") - 原 Colorscheme.text 替换
                    color: delegateRoot.active ? "#000000" : "#ffffff"

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }
}
