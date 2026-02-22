import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root
    
    // --- 开放给外部的属性 ---
    property bool isOpen: false
    property string title: ""
    property string icon: ""
    property int windowHeight: 420
    property int extraTopMargin: 0 
    
    property alias headerTools: headerToolsLayout.data 
    default property alias content: contentLayout.data

    // --- 内部通用逻辑 ---
    QtObject {
        id: theme
        property color background: Colorscheme.background
        property color surface: Colorscheme.surface
        property color primary: Colorscheme.primary
        property color error: Colorscheme.error
        property color text: Colorscheme.on_background
        property color subtext: Colorscheme.tertiary
        property color outline: Colorscheme.outline
        property int radius: 16
        property int padding: 16
    }

    anchors { right: true; top: true }
    margins {
        top: 66 + root.extraTopMargin
        right: 0 // 贴边
    }
    
    Behavior on margins.top { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // 【修改 1】大幅加宽隐形容器，给动画留足缓冲空间
    // 内容宽 340 + 右边距 10 + 左侧缓冲 50 = 400
    implicitWidth: 400
    implicitHeight: root.windowHeight

    visible: false
    color: "transparent"

    onIsOpenChanged: {
        if (isOpen) {
            if (exitAnim.running) exitAnim.stop()
            root.visible = true
            enterAnim.start()
        } else {
            if (enterAnim.running) enterAnim.stop()
            exitAnim.start()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-widget"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 计算最终停靠的位置 X
    // 容器宽(400) - 内容宽(340) - 右边距(10) = 50
    // 这意味着当 x=50 时，窗口视觉上距离屏幕右边缘正好 10px
    readonly property int targetX: 400 - 340 - 10
    readonly property int offScreenX: 400

    // ================= 动画修改区域 =================
    
    // 进场动画
    NumberAnimation {
        id: enterAnim
        target: bg
        property: "x"
        from: offScreenX  // 从 400 (屏幕外) 开始
        to: targetX       // 停在 50 (此时右侧留有 10px 缝隙)
        duration: 400 
        easing.type: Easing.OutBack 
        
        // 【修改 2】减小回弹幅度 (0.8 -> 0.4)
        // 这样看起来更稳重，不会有“撞击”感
        easing.overshoot: 0.4       
    }

    // 退场动画
    NumberAnimation {
        id: exitAnim
        target: bg
        property: "x"
        from: bg.x
        to: offScreenX    // 滑出到 400
        duration: 250
        easing.type: Easing.InExpo 
        onFinished: root.visible = false
    }
    // ==============================================

    Rectangle {
        id: bg
        width: 340
        height: root.implicitHeight
        color: theme.background
        radius: theme.radius
        
        border.width: 1
        border.color: Qt.rgba(0,0,0,0.1)
        
        // 初始位置设为屏幕外
        x: offScreenX

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: theme.padding
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text { text: root.icon; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20; color: theme.primary }
                Text { text: root.title; font.bold: true; font.pixelSize: 18; color: theme.text; Layout.fillWidth: true; Layout.leftMargin: 8 }
                RowLayout { id: headerToolsLayout }
                Item { width: 10 }
                Text {
                    text: "\uf00d"
                    font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18; color: theme.subtext
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.isOpen = false }
                }
            }

            ColumnLayout {
                id: contentLayout
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
