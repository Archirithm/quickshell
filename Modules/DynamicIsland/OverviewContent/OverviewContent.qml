import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Item {
    id: root
    signal closeRequested() 

    // 总体面板尺寸
    implicitWidth: 720
    implicitHeight: 360

    // ============================================================
    // 【Material You 精密几何组件库】
    // ============================================================

    // 1. 锁死为 64x64 的完美正圆 (1x1)
    component MiniCircleBtn : Item {
        property string icon: ""
        property bool active: false
        property string activeColor: Colorscheme.primary
        property string inactiveColor: Colorscheme.surface_container_highest
        property string iconActiveColor: Colorscheme.on_primary
        property string iconInactiveColor: Colorscheme.on_surface
        
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64

        Rectangle {
            anchors.fill: parent
            radius: width / 2 
            
            color: active ? activeColor : inactiveColor
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            scale: btnArea.pressed ? 0.85 : (btnArea.containsMouse ? 1.05 : 1.0)
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            Text { anchors.centerIn: parent; text: icon; color: active ? iconActiveColor : iconInactiveColor; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20 }
            MouseArea { id: btnArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.active = !parent.parent.active }
        }
    }

    // 2. 动态形变胶囊 (2x1，宽度 140，高度 64)
    component ShapeShiftTile : Rectangle {
        id: tile
        property string icon: ""; property string title: ""; property string subtitle: ""; property bool active: false
        
        Layout.columnSpan: 2
        Layout.preferredWidth: 140 // 64*2 + 12 = 140
        Layout.preferredHeight: 64
        
        radius: active ? 16 : height / 2
        Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
        color: active ? Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.15) : Colorscheme.surface_container_highest
        Behavior on color { ColorAnimation { duration: 250 } }
        scale: tileArea.pressed ? 0.94 : (tileArea.containsMouse ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        // 【修改点】：内部色块退回小巧精致的 40x40 尺寸
        Rectangle {
            id: innerBlock; width: 40; height: 40; anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            radius: tile.active ? 12 : width / 2
            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
            color: tile.active ? Colorscheme.primary : Colorscheme.surface_variant
            Behavior on color { ColorAnimation { duration: 250 } }
            Text { anchors.centerIn: parent; text: tile.icon; color: tile.active ? Colorscheme.on_primary : Colorscheme.on_surface; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 16 }
        }
        ColumnLayout {
            anchors.left: innerBlock.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: -2
            Text { text: tile.title; font.pixelSize: 14; font.bold: true; color: Colorscheme.on_surface }
            Text { text: tile.subtitle; font.pixelSize: 11; opacity: 0.8; color: Colorscheme.on_surface; visible: tile.subtitle !== "" }
        }
        MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.active = !tile.active }
    }

    // 3. 完美水滴滑块卡片 (彻底修复拖拽与气泡)
    component SliderCard : Rectangle {
        id: cardRoot
        property string iconName: ""; property string muteIconName: ""; property bool isMuted: false; property real sliderValue: 0.5; property bool canMute: false
        Layout.fillWidth: true; Layout.fillHeight: true 
        radius: 24; color: Colorscheme.surface_container_low 

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 24; spacing: 18

            Text { 
                text: cardRoot.isMuted ? cardRoot.muteIconName : cardRoot.iconName; color: cardRoot.isMuted ? Colorscheme.error : Colorscheme.on_surface_variant; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 20; Layout.preferredWidth: 26; horizontalAlignment: Text.AlignHCenter
                MouseArea { anchors.fill: parent; anchors.margins: -10; enabled: cardRoot.canMute; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: cardRoot.isMuted = !cardRoot.isMuted }
            }

            Slider {
                id: control
                Layout.fillWidth: true
                implicitHeight: 32 // 必须设置，否则热区为 0
                hoverEnabled: true 
                enabled: !cardRoot.isMuted
                opacity: cardRoot.isMuted ? 0.4 : 1.0
                
                Binding { target: control; property: "value"; value: cardRoot.isMuted ? 0 : cardRoot.sliderValue; when: !control.pressed }
                onMoved: { if (!cardRoot.isMuted) cardRoot.sliderValue = control.value }

                background: Item {
                    x: control.leftPadding; y: control.topPadding + control.availableHeight / 2 - height / 2; width: control.availableWidth; height: 16 
                    Rectangle { anchors.fill: parent; radius: 8; color: Colorscheme.surface_container_highest }
                    Rectangle { width: Math.max(0, control.visualPosition * parent.width); height: parent.height; color: Colorscheme.primary; radius: 8 }
                }
                
                handle: Rectangle {
                    x: control.leftPadding + control.visualPosition * (control.availableWidth - width); y: control.topPadding + control.availableHeight / 2 - height / 2; width: 4; height: 32; radius: 2; color: Colorscheme.on_surface 
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.top; anchors.bottomMargin: 8; width: 36; height: 36
                        visible: control.pressed || control.hovered; opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle { anchors.fill: parent; radius: 18; color: Colorscheme.primary_container }
                        Rectangle { width: 14; height: 14; radius: 2; color: Colorscheme.primary_container; rotation: 45; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: -4; z: -1 }
                        Text { anchors.centerIn: parent; text: Math.round(control.value * 100); color: Colorscheme.on_primary_container; font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
                    }
                }
            }
            Text { text: cardRoot.isMuted ? "Muted" : Math.round(control.value * 100) + "%"; color: cardRoot.isMuted ? Colorscheme.error : Colorscheme.on_surface_variant; font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font"; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
        }
    }

    // ============================================================
    // 【主体布局区】
    // ============================================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ============================================================
        // 【左半区：精准数学算法，292px 极简居中矩阵】
        // ============================================================
        ColumnLayout {
            // 左侧总宽: 64*4 + 12*3 = 292
            Layout.preferredWidth: 292
            Layout.maximumWidth: 292
            Layout.minimumWidth: 292
            Layout.fillHeight: true

            Item { Layout.fillHeight: true } // 上弹性弹簧，保证不被强行拉扯

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 12
                columnSpacing: 12

                // --- 第一/二排：2x2 完美的圆角正方形 (140x140) ---
                Rectangle {
                    Layout.rowSpan: 2
                    Layout.columnSpan: 2
                    Layout.preferredWidth: 140 
                    Layout.preferredHeight: 140
                    radius: 32 
                    color: Colorscheme.surface_container_highest

                    GridLayout {
                        anchors.fill: parent; anchors.margins: 14 
                        columns: 2; rowSpacing: 10; columnSpacing: 10

                        component AppBtn : Rectangle {
                            property string icon: ""; property color bgColor: "transparent"; property color fgColor: "white"
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 14 
                            color: bgColor
                            scale: appArea.pressed ? 0.88 : (appArea.containsMouse ? 1.08 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            Text { anchors.centerIn: parent; text: icon; color: fgColor; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 22 }
                            MouseArea { id: appArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                        }

                        AppBtn { icon: ""; bgColor: Colorscheme.primary; fgColor: Colorscheme.on_primary } // 浏览器
                        AppBtn { icon: ""; bgColor: Colorscheme.tertiary; fgColor: Colorscheme.on_tertiary } // 网络
                        AppBtn { icon: ""; bgColor: Colorscheme.inverse_surface; fgColor: Colorscheme.inverse_on_surface } // GitHub
                        AppBtn { icon: ""; bgColor: Colorscheme.error; fgColor: Colorscheme.on_error } // 哔哩哔哩
                    }
                }
                
                // 右侧自动掉入一、二排的胶囊
                ShapeShiftTile { icon: ""; title: "Wi-Fi"; subtitle: "Qs_5G"; active: true }
                ShapeShiftTile { icon: ""; title: "蓝牙"; subtitle: "已连接"; active: true }

                // --- 第三排：Power Profile (216x64) + 明暗模式 (64x64) ---
                Rectangle {
                    id: powerBar
                    Layout.columnSpan: 3
                    Layout.preferredWidth: 216 // 64*3 + 12*2
                    Layout.preferredHeight: 64
                    radius: height / 2; color: Colorscheme.surface_container_highest
                    
                    property int currentIndex: 1; property var modes: ["", "", ""]
                    
                    Rectangle {
                        id: indicator; width: 52; height: 52; radius: 26; color: Colorscheme.primary; y: 6 
                        property real segmentWidth: powerBar.width / 3; x: (powerBar.currentIndex * segmentWidth) + ((segmentWidth - width) / 2)
                        Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: powerBar.modes.length
                            Item {
                                width: powerBar.width / 3; height: powerBar.height
                                Text { anchors.centerIn: parent; text: powerBar.modes[index]; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18; color: powerBar.currentIndex === index ? Colorscheme.on_primary : Colorscheme.on_surface; Behavior on color { ColorAnimation { duration: 300 } } }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: powerBar.currentIndex = index }
                            }
                        }
                    }
                }
                MiniCircleBtn { icon: ""; active: true } 

                // --- 第四排：4个 64x64 纯正圆 ---
                MiniCircleBtn { icon: "" } 
                MiniCircleBtn { icon: ""; active: true } 
                MiniCircleBtn { icon: ""; activeColor: Colorscheme.error; iconActiveColor: Colorscheme.on_error; MouseArea { anchors.fill: parent; onClicked: root.closeRequested() } } 
                MiniCircleBtn { icon: ""; activeColor: Colorscheme.error; iconActiveColor: Colorscheme.on_error; MouseArea { anchors.fill: parent; onClicked: root.closeRequested() } } 
            }

            Item { Layout.fillHeight: true } // 下弹性弹簧
        }

        // ============================================================
        // 【极简分割线】
        // ============================================================
        Rectangle { Layout.preferredWidth: 2; Layout.fillHeight: true; color: Colorscheme.outline; opacity: 0.15; radius: 1 }

        // ============================================================
        // 【右半区：滑块区 + 底部设置电源组】
        // ============================================================
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 18 

            // 三大滑块 (自适应高度，完全释放)
            SliderCard { iconName: ""; muteIconName: ""; sliderValue: 0.8; canMute: true }
            SliderCard { iconName: ""; muteIconName: ""; sliderValue: 0.5; canMute: true }
            SliderCard { iconName: ""; sliderValue: 0.75; canMute: false }

            // 角落控制组
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52 
                spacing: 16

                Item { Layout.fillWidth: true } 

                component CornerBtn : Rectangle {
                    property string icon: ""; property color iconColor: "white"
                    width: 52; height: 52; radius: 18 // 无边框大圆角
                    scale: csArea.pressed ? 0.88 : (csArea.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: icon; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 22; color: parent.iconColor }
                    MouseArea { id: csArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                }

                CornerBtn { icon: ""; color: Colorscheme.tertiary_container; iconColor: Colorscheme.on_tertiary_container } // 设置
                CornerBtn { icon: ""; color: Colorscheme.error; iconColor: Colorscheme.on_error } // 关机
            }
        }
    }
}
