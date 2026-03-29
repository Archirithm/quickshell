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

    property int sidebarWidth: 420
    property int gap: 24 
    property int gooeyRadius: 26  

    // 设置为 Top，全屏看视频就不会被挡住了！
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-unified-sidebar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors { right: true; top: true; bottom: true }
    
    implicitWidth: 600
    color: "transparent"

    property int qsTargetHeight: 640
    property int targetX: 600 - sidebarWidth - gap
    property int offScreenX: 600

    Item {
        id: hitBoxRegion
        // 【核心】：只保留快捷面板的拦截区域
        x: qsShadow.x
        y: 66 
        width: sidebarWidth
        height: root.qsTargetHeight 
    }

    mask: Region { item: hitBoxRegion }

    Item {
        id: renderCanvas
        width: parent.width + 100 
        height: parent.height
        x: 0; y: 0

        Item {
            id: rawShapes
            anchors.fill: parent
            visible: false

            // 1. 你的原始快捷面板
            Rectangle {
                id: qsShadow
                width: root.sidebarWidth
                height: root.qsTargetHeight
                y: 66 
                x: WidgetState.qsOpen ? root.targetX : root.offScreenX
                radius: theme.radius
                color: "black" 
                Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.3 } }
            }

            // 2. 你的原始隐形墙！这才是果冻拉丝的灵魂！
            Rectangle {
                id: offscreenWall
                width: 100; height: parent.height; x: root.offScreenX; color: "black"
            }
        }

        // 3. 你的原始果冻滤镜！
        GaussianBlur {
            id: blurredShapes
            anchors.fill: parent; source: rawShapes
            radius: root.gooeyRadius
            samples: 1 + root.gooeyRadius * 2
            visible: false 
        }

        Rectangle { 
            id: solidBg; anchors.fill: parent; 
            color: theme.background; 
            visible: false 
        }

        ThresholdMask {
            id: gooeyLayer
            anchors.fill: parent; source: solidBg; maskSource: blurredShapes
            threshold: 0.51; spread: 0.02
        }
    }

    Item {
        anchors.fill: parent

        Item {
            width: qsShadow.width; height: qsShadow.height
            x: qsShadow.x; y: qsShadow.y; clip: true 
            QuickSettings { anchors.fill: parent }
        }
    }
}
