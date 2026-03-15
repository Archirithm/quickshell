import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects  // 引入 Qt 6 原生特效库
import qs.Services
import qs.config

Item {
    id: root

    // 将根节点改为 Item，脱离背景色的绑定限制
    implicitHeight: 36 
    implicitWidth: layout.width + 24

    // 1. 定义原背景（设为不可见，仅作为 MultiEffect 的渲染源）
    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colorscheme.background 
        radius: height / 2
        visible: false 
    }

    // 2. 使用 MultiEffect 渲染药丸背景 + 外部阴影（自带防裁切机制）
    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        // 调用 Colorscheme 的 shadow 属性，并赋予 40% 的透明度，让阴影更柔和
        shadowColor: Qt.alpha(Colorscheme.shadow, 0.4) 
        shadowBlur: 0.8    // 阴影模糊半径 (0.0 到 1.0)
        shadowVerticalOffset: 3 // 阴影向下偏移，增强悬浮感
        shadowHorizontalOffset: 0
    }

    // 3. 内部元素保持在最上层
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: Niri.workspaces

            delegate: Item {
                id: delegateRoot

                property bool active: model.isActive
                property bool hasWindows: false
                property bool isHovered: mouseArea.containsMouse

                function checkWindows() {
                    let found = false;
                    for (let i = 0; i < Niri.windows.count; i++) {
                        if (Niri.windows.get(i).workspaceId === model.wsId) {
                            found = true;
                            break;
                        }
                    }
                    hasWindows = found;
                }

                Connections {
                    target: Niri
                    function onWindowsUpdated() {
                        delegateRoot.checkWindows();
                    }
                }

                Component.onCompleted: checkWindows()

                implicitWidth: (active || isHovered) ? 32 : 12
                implicitHeight: 12 

                Behavior on implicitWidth { 
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic } 
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: height / 2 

                    // 颜色优先级：活动 > 有窗口 > 悬停 > 空闲
                    color: delegateRoot.active ? Colorscheme.primary 
                         : delegateRoot.hasWindows ? Colorscheme.on_surface 
                         : delegateRoot.isHovered ? Colorscheme.surface_variant 
                         : Colorscheme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true 
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", model.idx.toString()])
                }
            }
        }
    }
}
