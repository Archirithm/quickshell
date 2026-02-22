import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import qs.Components
import qs.config

Item {
    id: root
    
    required property var player
    
    readonly property bool isActive: root.visible && root.player

    property string artUrl: (isActive && player.trackArtUrl) ? player.trackArtUrl : ""
    property string title: (isActive && player.trackTitle) ? player.trackTitle : "No Media"
    property string artist: (isActive && player.trackArtist) ? player.trackArtist : ""
    
    // 进度百分比 (0.0 ~ 1.0)
    property double progress: (isActive && player.length > 0) ? (player.position / player.length) : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 15

        // --- 顶部信息栏 (封面 + 歌名) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            spacing: 15

            // 专辑封面
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 60
                radius: 12
                color: Colorscheme.background
                clip: true
                
                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: root.artUrl !== "" && status === Image.Ready
                }
                
                // 没封面时显示的图标
                Text {
                    anchors.centerIn: parent
                    text: "♫"
                    color: "#555"
                    font.pixelSize: 28
                    visible: root.artUrl === ""
                }
            }

            // 文本信息
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                
                Text {
                    text: root.title
                    color: "white"
                    font.bold: true
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: root.artist
                    color: "#aaa"
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // --- 进度条 (可拖动 & 防爆音版) ---
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 10 // 稍微给点高度方便布局

            Rectangle {
                id: trackBg
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                color: "#333333"
                radius: 3

                // 进度填充 (白色条)
                Rectangle {
                    id: progressFill
                    height: parent.height
                    radius: 3
                    color: "white"

                    width: {
                        if (seekMa.pressed) {
                            let w = seekMa.mouseX;
                            if (w < 0) return 0;
                            if (w > trackBg.width) return trackBg.width;
                            return w;
                        }
                        return Math.max(0, root.progress * trackBg.width)
                    }

                    // 【优化后的动画】
                    Behavior on width { 
                        enabled: root.visible && !seekMa.pressed
                        
                        SmoothedAnimation { 
                            // 这里的 velocity 是像素/秒。
                            // 设为 200 意味着它不紧不慢地滑过去，不会瞬间跳变
                            velocity: 200 
                            
                            // 设定一个最大时长作为保底，防止距离太远跑太久
                            duration: 1500
                            
                            // 关键：设置为 Sync 模式，让它更跟手
                            reversingMode: SmoothedAnimation.Sync
                        } 
                    }
                }

                // 交互区域
                MouseArea {
                    id: seekMa
                    anchors.fill: parent
                    // 上下扩大点击范围，不用瞄准那6像素
                    anchors.margins: -6 
                    cursorShape: Qt.PointingHandCursor
                    
                    // 【核心修改 3】只在松开鼠标时发送指令，防止音频鬼畜
                    onReleased: (mouse) => {
                        if (!root.player || root.player.length <= 0) return;

                        // 限制范围
                        let val = mouse.x;
                        if (val < 0) val = 0;
                        if (val > trackBg.width) val = trackBg.width;
                        
                        // 计算并跳转
                        let percent = val / trackBg.width;
                        root.player.position = percent * root.player.length;
                    }
                    
                    // 注意：这里不需要 onClicked 或 onPositionChanged
                    // onReleased 完美覆盖了点击跳转和拖拽跳转两种情况
                }
            }
        }

        // --- 控制按钮 (上一曲/暂停/下一曲) ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 45 
                
                // 1. 上一曲
                MouseArea {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if(root.player) root.player.previous()
                    
                    Image {
                        id: prevIcon
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: SvgIcon.previous
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: prevIcon
                        source: prevIcon
                        color: "white"
                    }
                }

                // 2. 播放/暂停
                MouseArea {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if(root.player) root.player.togglePlaying()
                    
                    Image {
                        id: playPauseIcon
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        source: (root.player && root.player.isPlaying) ? SvgIcon.pause : SvgIcon.play
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: playPauseIcon
                        source: playPauseIcon
                        color: "white"
                    }
                }

                // 3. 下一曲
                MouseArea {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if(root.player) root.player.next()
                    
                    Image {
                        id: nextIcon
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        source: SvgIcon.next
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: nextIcon
                        source: nextIcon
                        color: "white"
                    }
                }
            }
        }
    }
}
