import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
Item {
    id: root

    // 【改动1】接收音频节点对象，以便我们能修改音量
    required property var audioNode
    
    // 内部计算显示属性 (如果对象为空则给默认值)
    readonly property real volume: audioNode ? audioNode.volume : 0
    readonly property bool isMuted: audioNode ? audioNode.muted : false

    RowLayout {
        anchors.centerIn: parent
        width: parent.width - 24 
        spacing: 12

        // 图标 (点击静音/解除静音)
        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 18 
                text: root.isMuted ? "" : ""
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            
            // 【新增】点击图标切换静音
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.audioNode) root.audioNode.muted = !root.audioNode.muted
            }
        }

        // 音量条容器
        Rectangle {
            id: barContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            
            color: Colorscheme.background
            radius: 3

            // 进度填充
            Rectangle {
                height: parent.height
                radius: 3
                color: "white"
                width: Math.max(0, root.volume * parent.width)
                
                // 拖动时禁用动画，看着更跟手；非拖动(系统调节)时启用动画
                Behavior on width { 
                    enabled: !dragArea.pressed
                    NumberAnimation { duration: 80 } 
                }
            }

            // 【新增】拖拽交互区域
            MouseArea {
                id: dragArea
                // 让感应区稍微比进度条高一点(20px)，方便手指/鼠标按住，不用瞄得太准
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 20 
                
                cursorShape: Qt.PointingHandCursor
                
                // 阻止事件冒泡：防止拖动音量时触发灵动岛的展开/收起
                preventStealing: true

                // 核心逻辑：计算比例并设置音量
                function setVol(mouseX) {
                    if (!root.audioNode) return
                    // 计算 0.0 ~ 1.0 的比例
                    let p = mouseX / width
                    if (p < 0) p = 0
                    if (p > 1) p = 1
                    root.audioNode.volume = p
                    
                    // 拖动时自动解除静音
                    if (root.isMuted) root.audioNode.muted = false
                }

                onPressed: (mouse) => setVol(mouse.x)
                onPositionChanged: (mouse) => setVol(mouse.x)
            }
        }
    }
}
