import QtQuick
import QtQuick.Layouts
import qs.config

Item {
    id: toolsRoot

    Row {
        anchors.centerIn: parent
        spacing: 8

        // 使用 Repeater 循环生成按钮，安全且优雅
        Repeater {
            model: [
                { icon: "colorize",         tip: "取色器" },
                { icon: "videocam",         tip: "录屏" },
                { icon: "gif",              tip: "录制 GIF" },
                { icon: "crop_free",        tip: "普通截屏" },
                { icon: "height",           tip: "截长屏" },
                { icon: "document_scanner", tip: "OCR 识别" },
                { icon: "mic",              tip: "录音" }
            ]

            Rectangle {
                width: 48
                height: 48
                radius: 12
                
                // 悬浮变色逻辑
                color: toolsMouse.containsMouse ? Colorscheme.surface_variant : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    
                    // 【核心修复】：使用了你系统中确实存在的字体名称
                    font.family: "Material Symbols Rounded" 
                    font.pixelSize: 22
                    color: Colorscheme.on_surface
                }

                MouseArea {
                    id: toolsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        console.log("TODO: 触发工具 - " + modelData.tip)
                    }
                }
            }
        }
    }
}
