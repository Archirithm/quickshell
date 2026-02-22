import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Services.Mpris
import qs.config

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 160
    
    // 基础背景色
    color: "#000000"
    radius: Sizes.lockCardRadius
    
    // 【核心】裁切圆角，因为内部的 Image 是铺满的
    clip: true

    // ================== MPRIS 逻辑 ==================
    property var player: {
        let list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i];
        }
        return list.length > 0 ? list[0] : null;
    }

    property bool hasMedia: player !== null
    property bool isPlaying: player && player.isPlaying
    property string artUrl: (player && player.trackArtUrl) ? player.trackArtUrl : ""
    property string title: (player && player.trackTitle) ? player.trackTitle : "No Media"
    property string artist: (player && player.trackArtist) ? player.trackArtist : "Not Playing"

    // ================== 1. 全背景封面 ==================
    Image {
        id: coverArt
        anchors.fill: parent
        source: root.artUrl
        // 保持比例裁切填充
        fillMode: Image.PreserveAspectCrop 
        visible: root.artUrl !== ""
        smooth: true
    }

    // ================== 2. 黑色渐变遮罩 (Gradient Scrim) ==================
    // 从左侧黑色过渡到右侧透明，保证左侧文字可读
    Rectangle {
        anchors.fill: parent
        visible: root.artUrl !== ""
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#cc000000" } // 左侧 80% 黑
            GradientStop { position: 0.6; color: "#66000000" } // 中间半透明
            GradientStop { position: 1.0; color: "#00000000" } // 右侧完全透明
        }
    }

    // 无媒体时的默认背景 (微弱的渐变)
    Rectangle {
        anchors.fill: parent
        visible: root.artUrl === ""
        color: Colorscheme.surface_container
        
        Text {
            anchors.centerIn: parent
            text: ""
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 40
            color: Colorscheme.on_surface_variant
            opacity: 0.2
        }
    }

    // ================== 3. 内容层 ==================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 0

        // 顶部占位 (把内容推到下面或者居中)
        Item { Layout.fillHeight: true }

        // 标签
        Text {
            text: "Now playing"
            color: Colorscheme.primary
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 12
            font.bold: true
            opacity: 0.9
        }

        // 歌名
        Text {
            text: root.title
            color: "white" // 无论主题如何，在黑色遮罩上必须是白色
            font.family: Sizes.fontFamily
            font.bold: true
            font.pixelSize: 20
            Layout.fillWidth: true
            Layout.maximumWidth: root.width * 0.8 // 防止文字太长挡住封面主体
            elide: Text.ElideRight
            Layout.topMargin: 4
        }
        
        // 歌手
        Text {
            text: root.artist
            color: "#cccccc" // 浅灰
            font.family: Sizes.fontFamily
            font.pixelSize: 14
            Layout.fillWidth: true
            Layout.maximumWidth: root.width * 0.8
            elide: Text.ElideRight
            Layout.bottomMargin: 15
        }

        // 按钮组 (居左显示)
        RowLayout {
            spacing: 20
            
            // 上一曲
            Text { 
                text: "" 
                font.family: Sizes.fontFamilyMono; font.pixelSize: 22
                color: "#dddddd"
                MouseArea { anchors.fill: parent; onClicked: if(root.player) root.player.previous() }
            }
            
            // 播放/暂停 (圆形按钮)
            Rectangle {
                width: 40; height: 40; radius: 20
                color: Colorscheme.primary
                
                Text { 
                    anchors.centerIn: parent
                    text: root.isPlaying ? "" : ""
                    font.family: Sizes.fontFamilyMono; font.pixelSize: 16
                    color: Colorscheme.on_primary
                }
                MouseArea { anchors.fill: parent; onClicked: if(root.player) root.player.togglePlaying() }
            }

            // 下一曲
            Text { 
                text: "" 
                font.family: Sizes.fontFamilyMono; font.pixelSize: 22
                color: "#dddddd"
                MouseArea { anchors.fill: parent; onClicked: if(root.player) root.player.next() }
            }
        }
        
        // 底部留白
        Item { height: 5 }
    }
}
