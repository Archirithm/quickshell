import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Item {
    id: root
    // 定义关闭信号，对应 DynamicIsland.qml 中的 onCloseRequested
    signal closeRequested() 

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24

        // ============================================================
        // 【左半区：系统控制台 (按钮与滑块)】
        // ============================================================
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.38
            Layout.fillHeight: true
            spacing: 15

            // 1. 快捷开关网格
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                rowSpacing: 10
                columnSpacing: 10

                // 按钮组件模板
                component QuickButton : Rectangle {
                    property string icon: ""
                    property string label: ""
                    property bool active: false
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 12
                    color: active ? Colorscheme.primary : Colorscheme.surface_container_highest
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text { 
                            text: icon; color: active ? Colorscheme.on_primary : Colorscheme.on_surface
                            font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 16 
                        }
                        Text { 
                            text: label; color: active ? Colorscheme.on_primary : Colorscheme.on_surface
                            font.pixelSize: 13; font.bold: true 
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: parent.active = !parent.active }
                }

                QuickButton { icon: ""; label: "深色模式"; active: true }
                QuickButton { icon: ""; label: "免打扰" }
                QuickButton { icon: ""; label: "静音" }
                QuickButton { icon: ""; label: "咖啡因"; active: true }
            }

            // 2. 滑块区域
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: 20

                // 亮度
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: " 亮度"; color: Colorscheme.on_surface; font.pixelSize: 12 }
                    Slider { Layout.fillWidth: true; value: 0.7 }
                }

                // 音量
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: " 音量"; color: Colorscheme.on_surface; font.pixelSize: 12 }
                    Slider { Layout.fillWidth: true; value: 0.5 }
                }
            }
            
            Item { Layout.fillHeight: true } // 底部推力
        }

        // 分割线
        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Colorscheme.outline; opacity: 0.2 }

        // ============================================================
        // 【右半区：不规则磁贴 (Bento Box)】
        // ============================================================
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 4
            rows: 4
            columnSpacing: 12
            rowSpacing: 12

            // 磁贴模板
            component Tile : Rectangle {
                property string bg: Colorscheme.surface_container_high
                property string txt: ""
                property string icon: ""
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: bg
                
                ColumnLayout {
                    anchors.centerIn: parent
                    Text { text: icon; font.pixelSize: 32; Layout.alignment: Qt.AlignHCenter }
                    Text { text: txt; font.bold: true; Layout.alignment: Qt.AlignHCenter; opacity: 0.8 }
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: {
                        console.log("Launched: " + txt)
                        root.closeRequested() // 点击磁贴后关闭控制中心
                    }
                }
            }

            // 布局：音乐 (2x2)
            Tile { Layout.columnSpan: 2; Layout.rowSpan: 2; bg: "#f3d2c1"; txt: "Music"; icon: "🎵" }
            
            // 布局：终端 (1x1)
            Tile { Layout.columnSpan: 1; Layout.rowSpan: 1; bg: "#1e1e2e"; txt: ""; icon: "🐚" }
            
            // 布局：图片磁贴 (1x1)
            Rectangle {
                Layout.columnSpan: 1; Layout.rowSpan: 1; Layout.fillWidth: true; Layout.fillHeight: true
                radius: 16; color: Colorscheme.surface_container_highest; clip: true
                Image { anchors.fill: parent; source: "https://picsum.photos/200"; fillMode: Image.PreserveAspectCrop }
            }

            // 布局：浏览器 (2x2)
            Tile { Layout.columnSpan: 2; Layout.rowSpan: 2; bg: "#bae1ff"; txt: "Browser"; icon: "🌐" }

            // 布局：宽磁贴 (2x1)
            Tile { Layout.columnSpan: 2; Layout.rowSpan: 1; bg: "#ffffba"; txt: "Weather"; icon: "🌤️" }
        }
    }
}
