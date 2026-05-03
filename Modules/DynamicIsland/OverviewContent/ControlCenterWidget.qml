import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.Modules.DynamicIsland.OverviewContent 

Item {
    id: root

    // ============================================================
    // 【组件库】
    // ============================================================
    component MiniCircleBtn : Item {
        property string icon: ""
        property bool active: false
        property color activeColor: Appearance.colors.colPrimary
        property color inactiveColor: Appearance.colors.colLayer4
        property color iconActiveColor: Appearance.colors.colOnPrimary
        property color iconInactiveColor: Appearance.colors.colOnSurface
        
        signal clicked()

        Layout.preferredWidth: 48
        Layout.preferredHeight: 48

        Rectangle {
            anchors.fill: parent
            radius: width / 2 
            color: active ? activeColor : inactiveColor
            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
            scale: btnArea.pressed ? 0.85 : (btnArea.containsMouse ? 1.05 : 1.0)
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            Text { 
                anchors.centerIn: parent
                text: icon
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 16
                color: active ? iconActiveColor : iconInactiveColor 
            }

            MouseArea { 
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor 
                onClicked: parent.parent.clicked() 
            }
        }
    }

    component ShapeShiftTile : Rectangle {
        id: tile
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        
        signal clicked()

        Layout.preferredWidth: 112
        Layout.preferredHeight: 48
        
        radius: active ? 12 : height / 2
        Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
        
        color: active ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.15) : Appearance.colors.colLayer4
        Behavior on color { ColorAnimation { duration: 250 } }
        
        scale: tileArea.pressed ? 0.94 : (tileArea.containsMouse ? 1.02 : 1.0)
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Rectangle {
            id: innerBlock
            width: 32
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            radius: tile.active ? 10 : width / 2
            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
            color: tile.active ? Appearance.colors.colPrimary : Appearance.colors.colLayer2Hover
            Behavior on color { ColorAnimation { duration: 250 } }
            
            Text { 
                anchors.centerIn: parent
                text: tile.icon
                color: tile.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 14 
            }
        }

        ColumnLayout {
            anchors.left: innerBlock.right
            anchors.leftMargin: 10
            anchors.right: parent.right      // 【新增】：强行规定右侧边界
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2

            Text { 
                text: tile.title
                font.pixelSize: 13
                font.bold: true
                color: Appearance.colors.colOnSurface 
                Layout.fillWidth: true       // 【新增】：填满剩余空间
                elide: Text.ElideRight       // 【新增】：超出自动变成省略号
            }
            Text { 
                text: tile.subtitle
                font.pixelSize: 10
                opacity: 0.8
                color: Appearance.colors.colOnSurface
                visible: tile.subtitle !== "" 
                Layout.fillWidth: true       // 【新增】：填满剩余空间
                elide: Text.ElideRight       // 【新增】：超出自动变成省略号
            }
        }

        MouseArea { 
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked() 
        }
    }

    component CornerBtn : Rectangle {
        property string icon: ""
        property color bgColor: "transparent"
        property color fgColor: "white"

        signal clicked()

        width: 48
        height: 48
        radius: 14 
        color: bgColor
        
        scale: btnArea.pressed ? 0.85 : (btnArea.containsMouse ? 1.05 : 1.0)
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        Text {
            anchors.centerIn: parent
            text: icon
            color: fgColor 
            font.family: "Font Awesome 6 Free Solid"
            font.pixelSize: 18
        }

        MouseArea { 
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor 
            onClicked: parent.parent.clicked()
        }
    }

    // ============================================================
    // 【网格布局】
    // ============================================================
    GridLayout {
        anchors.top: parent.top   
        anchors.horizontalCenter: parent.horizontalCenter 
        anchors.margins: 4        
        
        columns: 4      
        rowSpacing: 16  
        columnSpacing: 16

        ShapeShiftTile { 
            Layout.row: 0
            Layout.column: 0
            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignHCenter
            icon: ""
            title: "Wi-Fi"
            active: ControlBackend.wifiEnabled 
            subtitle: ControlBackend.wifiEnabled ? "已连接" : "已断开"
            onClicked: ControlBackend.toggleWifi()
        }

        ShapeShiftTile { 
            Layout.row: 0
            Layout.column: 2
            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignHCenter
            icon: ""
            title: "蓝牙"
            active: ControlBackend.bluetoothEnabled 
            // 【修改】：缩减文本，完美对齐 Wi-Fi 视觉比例
            subtitle: !ControlBackend.bluetoothEnabled ? "已关闭" : (ControlBackend.bluetoothConnected ? "已连接" : "已开启")
            onClicked: ControlBackend.toggleBluetooth()
        }

        Rectangle {
            id: powerBar
            Layout.row: 1
            Layout.column: 0
            Layout.columnSpan: 3 
            Layout.preferredWidth: 176
            Layout.preferredHeight: 48
            radius: 24
            
            color: Appearance.colors.colLayer4
            
            property int currentIndex: 1
            property var modes: ["", "", ""]
            
            Rectangle {
                id: indicator
                width: 40
                height: 40
                radius: 20
                color: Appearance.colors.colPrimary
                y: 4 
                property real segmentWidth: powerBar.width / 3
                x: (powerBar.currentIndex * segmentWidth) + ((segmentWidth - width) / 2)
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Row {
                anchors.fill: parent
                Repeater {
                    model: powerBar.modes.length
                    Item {
                        width: powerBar.width / 3
                        height: powerBar.height
                        Text { 
                            anchors.centerIn: parent
                            text: powerBar.modes[index]
                            font.family: "Font Awesome 6 Free Solid"
                            font.pixelSize: 16
                            color: powerBar.currentIndex === index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                            Behavior on color { ColorAnimation { duration: 300 } } 
                        }
                        MouseArea { 
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor 
                            onClicked: {
                                powerBar.currentIndex = index;
                                let mode = index === 0 ? "power-saver" : (index === 1 ? "balanced" : "performance");
                                Quickshell.execDetached(["powerprofilesctl", "set", mode]);
                            }
                        }
                    }
                }
            }
        }
        
        MiniCircleBtn { 
            Layout.row: 1
            Layout.column: 3
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter 
            icon: ""
            property bool isDark: true
            active: isDark
            onClicked: {
                isDark = !isDark;
                let scheme = isDark ? "prefer-dark" : "default";
                Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme]);
            }
        } 

        MiniCircleBtn { 
            Layout.row: 2
            Layout.column: 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            icon: ""
            active: ControlBackend.dndEnabled
            onClicked: ControlBackend.toggleDnd()
        } 

        MiniCircleBtn { 
            Layout.row: 2
            Layout.column: 1
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            icon: ""
            active: ControlBackend.caffeineEnabled
            onClicked: ControlBackend.toggleCaffeine()
        } 
    }

    // ============================================================
    // 【底部常驻功能按钮】
    // ============================================================
    Row {
        anchors.bottom: parent.bottom 
        anchors.right: parent.right
        anchors.margins: 4
        spacing: 16

        CornerBtn { 
            icon: ""
            bgColor: Appearance.colors.colTertiaryContainer
            fgColor: Appearance.colors.colOnTertiaryContainer 
            onClicked: console.log("等待后续开发：控制面板") // 占坑，先不绑定
        }

        CornerBtn { 
            icon: ""
            bgColor: Appearance.colors.colError
            fgColor: Appearance.colors.colOnError 
            // 【修改】：完全绑定 wlogout 指令，完美对齐顶栏
            onClicked: Quickshell.execDetached(["wlogout", "-p", "layer-shell", "-b", "2"])
        }
    }
}
