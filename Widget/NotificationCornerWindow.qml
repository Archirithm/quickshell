// Widget/NotificationCornerWindow.qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.Widget.common

PanelWindow {
    id: root
    Theme { id: theme }

    // 【精准数学对齐】：总宽度 444
    // 主面板宽度 400 + 内凹半径 44 = 444（完美对齐上方 420+24 的左边缘！）
    property int sidebarWidth: 444
    property int sidebarHeight: 680 
    
    // 【放大内凹曲线】：44px的超大猫耳朵，曲线极度明显且优雅
    property int earRadius: 44 
    property int shadowOffset: 40 

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-notification-corner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors { right: true; bottom: true }
    
    implicitWidth: sidebarWidth + earRadius + shadowOffset
    implicitHeight: sidebarHeight + earRadius + shadowOffset
    color: "transparent"

    property int targetX: shadowOffset
    property int offScreenX: implicitWidth

    // 鼠标拦截区域：包含主面板和内凹耳朵区域
    Item {
        id: hitBoxRegion
        x: slidingContainer.x
        y: slidingContainer.y
        width: sidebarWidth + earRadius
        height: sidebarHeight + earRadius
    }
    mask: Region { item: hitBoxRegion }

    Item {
        id: slidingContainer
        width: sidebarWidth + earRadius
        height: sidebarHeight + earRadius
        x: WidgetState.notifOpen ? targetX : offScreenX
        y: shadowOffset
        
        Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.3 } }

        // ============================================================
        // 1. 阴影底片 (Shadow Source)
        // ============================================================
        Item {
            id: shadowSource
            anchors.fill: parent
            visible: false

            Rectangle {
                id: shadowMain
                width: sidebarWidth; height: sidebarHeight
                anchors.right: parent.right; anchors.bottom: parent.bottom
                radius: theme.radius
                color: "black"
                
                Rectangle { width: theme.radius; height: theme.radius; anchors.top: parent.top; anchors.right: parent.right; color: "black" }
                Rectangle { width: theme.radius; height: theme.radius; anchors.bottom: parent.bottom; anchors.left: parent.left; color: "black" }
                Rectangle { width: theme.radius; height: theme.radius; anchors.bottom: parent.bottom; anchors.right: parent.right; color: "black" }
            }

            Canvas {
                anchors.bottom: shadowMain.top; anchors.right: parent.right
                width: earRadius; height: earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.fillStyle = "black";
                    ctx.beginPath(); ctx.moveTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                    ctx.arc(0, 0, width, Math.PI/2, 0, true); ctx.fill();
                }
            }

            Canvas {
                anchors.right: shadowMain.left; anchors.bottom: parent.bottom
                width: earRadius; height: earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset(); ctx.fillStyle = "black";
                    ctx.beginPath(); ctx.moveTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                    ctx.arc(0, 0, width, Math.PI/2, 0, true); ctx.fill();
                }
            }
        }

        

        // ============================================================
        // 3. 实体与内凹曲线 
        // ============================================================
        Item {
            anchors.fill: parent

            Rectangle {
                id: mainRect
                width: sidebarWidth; height: sidebarHeight
                anchors.right: parent.right; anchors.bottom: parent.bottom
                radius: theme.radius
                
                // 【核心修改】：背景统一使用 Colorscheme.background
                color: theme.background 
                
                Rectangle { width: theme.radius; height: theme.radius; anchors.top: parent.top; anchors.right: parent.right; color: parent.color }
                Rectangle { width: theme.radius; height: theme.radius; anchors.bottom: parent.bottom; anchors.left: parent.left; color: parent.color }
                Rectangle { width: theme.radius; height: theme.radius; anchors.bottom: parent.bottom; anchors.right: parent.right; color: parent.color }
            }

            Canvas {
                id: topRightEar
                anchors.bottom: mainRect.top; anchors.right: parent.right
                width: earRadius; height: earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    // 【核心修改】：背景统一使用 Colorscheme.background
                    ctx.fillStyle = theme.background; 
                    ctx.beginPath(); ctx.moveTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                    ctx.arc(0, 0, width, Math.PI/2, 0, true); ctx.fill();
                }
                // 热重载颜色监听
                Connections { target: Colorscheme; function onBackgroundChanged() { topRightEar.requestPaint() } }
            }

            Canvas {
                id: bottomLeftEar
                anchors.right: mainRect.left; anchors.bottom: parent.bottom
                width: earRadius; height: earRadius
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset();
                    // 【核心修改】：背景统一使用 Colorscheme.background
                    ctx.fillStyle = theme.background; 
                    ctx.beginPath(); ctx.moveTo(width, 0); ctx.lineTo(width, height); ctx.lineTo(0, height);
                    ctx.arc(0, 0, width, Math.PI/2, 0, true); ctx.fill();
                }
                // 热重载颜色监听
                Connections { target: Colorscheme; function onBackgroundChanged() { bottomLeftEar.requestPaint() } }
            }
        }

        Item {
            width: sidebarWidth; height: sidebarHeight
            anchors.right: parent.right; anchors.bottom: parent.bottom
            clip: true 
            NotificationContent { anchors.fill: parent }
        }
    }
}
