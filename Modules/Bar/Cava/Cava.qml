import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
Item {
    id: root
    
    // ============================================================
    // 1. 属性定义
    // ============================================================
    property bool expanded: false
    property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/cava.sh"

    property int collapsedWidth: 40
    property int autoWidth: (cavaText.contentWidth > 0 ? cavaText.contentWidth : 50) + 45
    
    width: expanded ? autoWidth : collapsedWidth
    height: Sizes.barHeight
    
    clip: true
    
    implicitWidth: width
    implicitHeight: height

    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.width 
        
        color: Colorscheme.background
        radius: 10
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            
            // ★★★ 核心修复：动态右边距 ★★★
            // 收起时：(40 - 图标宽) / 2 -> 算术级绝对居中
            // 展开时：8 -> 保持紧凑
            anchors.rightMargin: root.expanded ? 8 : (root.collapsedWidth - iconText.contentWidth) / 2
            
            // 加上动画，让图标从居中位置滑到右边位置，非常丝滑
            Behavior on anchors.rightMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }
            
            spacing: 6
            layoutDirection: Qt.RightToLeft

            // 1. 图标 (加了 ID 以便计算宽度)
            Text {
                id: iconText 
                text: "󰎈" 
                color: root.expanded ? Colorscheme.on_primary_container : "#ffffff"
                font.family: Sizes.fontIcon
                font.pixelSize: 18
                
                // 垂直居中
                Layout.alignment: Qt.AlignVCenter
            }

            // 2. 分割线
            Rectangle {
                width: 1; height: 16; color: "#444"
                Layout.alignment: Qt.AlignVCenter
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // 3. 字符频谱文本 (贴底布局)
            Item {
                Layout.preferredWidth: cavaText.contentWidth
                Layout.fillHeight: true
                
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    id: cavaText
                    text: "" 
                    color: Colorscheme.on_primary_container
                    
                    font.family: Sizes.fontFamily 
                    font.pixelSize: 8       
                    font.letterSpacing: 0.3 
                    
                    // 底部对齐
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.right: parent.right
                    
                    // 拉伸效果
                    transform: Scale {
                        origin.y: cavaText.height
                        yScale: 2.5 
                        xScale: 1.0
                    }
                }
            }
        }
    }

    Process {
        id: cavaScript
        command: ["bash", root.scriptPath]
        running: root.expanded
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let cleanData = data.trim()
                if (cleanData !== "") {
                    cavaText.text = cleanData
                }
            }
        }
    }
}
